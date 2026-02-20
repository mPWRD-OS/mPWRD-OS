#!/usr/bin/env bash

function pre_umount_final_image__perf_fstab_noatime_apply() {
	local rootfs="${MOUNT}"
	if [[ ! -f "${rootfs}/etc/fstab" ]]; then
		return 0
	fi

	# Why: on low-end flash + low RAM devices, atime updates create extra write
	# churn for ordinary reads. Enforcing noatime on / reduces metadata writes.
	#
	# How: rewrite only the root (/) mount options:
	# - keep existing non-atime options
	# - drop relatime/strictatime
	# - ensure noatime is present exactly once
	local tmp_fstab
	tmp_fstab="$(mktemp)"
	awk 'BEGIN{OFS="\t"}
/^[[:space:]]*#/ {print; next}
NF>=4 && $2=="/" {
  n=split($4,a,",")
  delete seen
  out=""
  have_noatime=0
  for(i=1; i<=n; i++){
    opt=a[i]
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", opt)
    if(opt=="") continue
    if(opt=="relatime" || opt=="strictatime") continue
    if(opt=="noatime") have_noatime=1
    if(!(opt in seen)){
      seen[opt]=1
      out = (out=="" ? opt : out "," opt)
    }
  }
  if(!have_noatime){
    out = (out=="" ? "noatime" : out ",noatime")
  }
  $4=out
  print
  next
}
{print}' "${rootfs}/etc/fstab" > "${tmp_fstab}"
	install -m 0644 "${tmp_fstab}" "${rootfs}/etc/fstab"
	rm -f "${tmp_fstab}"
	return 0
}
