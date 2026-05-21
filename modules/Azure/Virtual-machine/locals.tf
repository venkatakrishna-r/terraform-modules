locals {
  user_creation_script = length(var.users) > 0 ? join("\n", flatten([
    "<powershell>",
    [
      for u in var.users : flatten([
        "New-LocalUser -Name \"${u.name}\" -Password (ConvertTo-SecureString \"${u.password}\" -AsPlainText -Force)",
        [for g in lookup(u, "groups", ["Administrators"]) : "Add-LocalGroupMember -Group \"${g}\" -Member \"${u.name}\""]
      ])
    ],
    "</powershell>"
  ])) : null
}