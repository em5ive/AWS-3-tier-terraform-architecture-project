# Terraform learning reference

Prefer hints and explanations unless implementation is explicitly requested.
Explain proposed changes and ask for permission before editing files.

## Security groups and dependency cycles

Use this example when revisiting Terraform code structure.

Originally, the ALB group's inline egress rule referenced the web group, while
the web group's inline ingress rule referenced the ALB group. Validation
reported a dependency cycle: each group needed the other created first.

The revised security_groups.tf separates groups from their rules:

1. Two aws_security_group resources define the groups without inline rules.
2. Separate aws_vpc_security_group_ingress_rule and
   aws_vpc_security_group_egress_rule resources define permissions.
3. Rules reference groups through security_group_id and, where needed,
   referenced_security_group_id.

Terraform can create both groups first, then their rules. References determine
dependencies; file order does not determine creation order. Avoid mixing inline
and standalone rules for the same group because rule ownership can conflict.

Traffic intent:

- Internet to ALB: inbound TCP port 80.
- ALB to web: outbound TCP port 80 on ALB; inbound TCP port 80 on web.
- Web outbound: all IPv4 destinations and all protocols.

Use tcp with ports 80 through 80 for HTTP's usual port. Protocol -1 means all
protocols; omit port fields for that standalone rule.

Validation checks configuration structure. Review a successful Terraform plan
against AWS state before applying infrastructure changes.
