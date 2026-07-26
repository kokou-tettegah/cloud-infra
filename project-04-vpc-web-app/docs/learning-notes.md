# Project 4 — Learning Notes

## Concepts that clicked doing this hands-on
- **Public vs. private subnet is just a routing decision, not a setting.** A subnet isn't
  inherently "public" — it's public because its route table sends 0.0.0.0/0 to an Internet
  Gateway. The private subnet is private because its route table sends 0.0.0.0/0 to a NAT
  Gateway instead. Same VPC, same subnet mechanics, different route table target.
- **NAT Gateway = outbound only, one-way door.** It lets the private instance initiate
  connections out, but nothing from the internet can initiate a connection in. That's the
  whole value proposition — patching/updates without exposure.
- **Security groups are stateful and layer on top of routing, not instead of it.** Even
  though the private subnet has no route to an Internet Gateway, I still scoped its security
  group to only trust the bastion's SG — defense in depth, not relying on routing alone.

## Bug I hit and had to actually debug: SSH ProxyJump silently using the wrong key
Used `ssh -J bastion target` to hop through the bastion to the private instance. Direct SSH
to the bastion alone worked fine with `-i project-04-key.pem`. But the exact same flags
through `-J` failed with `Permission denied`.

Diagnosed with `ssh -v`: the jump-hop authentication was trying my *default* keys
(`id_rsa`, `id_ed25519`, etc. — leftover from the GitHub cloud-engineering SSH identity set
up in Project 1) instead of `project-04-key.pem`. `-J` on the command line does not reliably
inherit `-i` / `IdentitiesOnly=yes` for the jump-host leg on this setup — likely interacting
with the existing `~/.ssh/config` aliasing.

**Fix:** replaced `-J` with an explicit `ProxyCommand` that pins the identity file on both
hops:
ssh -o IdentitiesOnly=yes -i ~/.ssh/project-04-key.pem \
  -o "ProxyCommand=ssh -o IdentitiesOnly=yes -i ~/.ssh/project-04-key.pem -W %h:%p ec2-user@<bastion-ip>" \
  ec2-user@<private-ip>
**Takeaway:** when SSH auth fails through a jump host but works directly, don't assume it's
a security-group or key problem first — check with `-v` whether the *right identity file*
is even being offered for that specific hop. Multiple SSH identities on one machine (which
I already have, deliberately, per the account-separation setup) can silently interfere with
flags that "should" just work.

## Mistake caught before it mattered
Gave Claude a `cat >> terraform/main.tf` append command while already `cd`'d into the
`terraform/` directory — path resolved to a nonexistent nested `terraform/terraform/main.tf`,
so the append silently failed (bash printed "No such file or directory" but didn't halt the
session). Caught it because `terraform plan` said "No changes" when it should have shown new
resources — a good reminder that an unexpected "no changes" is itself a signal something's
wrong, not just a boring confirmation.

## Explain-out-loud check
Could I explain to someone else, without notes, why the private instance can `curl` out to
the internet but nothing can `ssh` into it directly? Yes: routing (NAT gateway route) allows
initiated-from-inside traffic out; no route exists for initiated-from-outside traffic in;
and even if a route did exist, the security group would still block anything not coming
from the bastion's SG specifically.
