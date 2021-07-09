[toc]

## pd-ctl jq 

### 找出大于三副本的 region 信息

```
region --jq=".regions[].peers|if (length > 3) then . else empty end"
```

### 找出副本数大于 3 的 region 信息，并对输出的 region 信息统计副本数量

```
region --jq=".regions[].peers|if (length > 3) then . else empty end | length"
4
```

### 找出副本数大于 3 的 region 信息的 ID 信息，并通过数组输出

```
region --jq=".regions[].peers|if (length > 3) then . else empty end|map(.store_id)"
```

### 找出没有 leader 的 region 信息

```
region --jq='.regions[]|select(has("leader")|not)|{id: .id, peer_stores: [.peers[].store_id]}'
```

### 所有在 store1 上有副本并且没有其他 DownPeer 的 region 信息

```
region --jq=".regions[] | {id: .id, peer_stores: [.peers[].store_id] | select(length>1 and any(.==1) and all(.!=(30,31)))}"
{"id":24,"peer_stores":[1,32,33]}
```

### 查找所有 Down 副本数量大于正常副本数量的所有 Region

```
region --jq='.regions[] | {id: .id, peer_stores: [.peers[].store_id] | select(length as $total | map(if .==(1,240387) then . else empty end) | length>=$total-length) }'
```