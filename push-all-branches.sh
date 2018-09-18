#!/usr/bin/env bash

fetch_get_branch_list() {
    git branch --no-color | sed -e 's/^..//'
}

for branch in $(fetch_get_branch_list); do
    git push -u origin $branch
done
