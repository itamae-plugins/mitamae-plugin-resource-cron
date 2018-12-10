# mitamae-plugin-resource-cron

MItamae plugin to reproduce the behavior of `cron` resource in Chef v12.13.37.

## Usage

See https://github.com/itamae-kitchen/mitamae/blob/v1.6.3/PLUGINS.md.

Put this repository as ./plugins/mitamae-plugin-resource-cron, and execute mitamae local where you can find ./plugins directory.

### Example

```rb
cron 'foo_bar' do
  hour '6'
  minute '30'
  command 'echo hello'
end
```

## License

Chef - A configuration management system

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | Adam Jacob (<adam@chef.io>)
| **Copyright:**       | Copyright 2008-2016, Chef Software, Inc.
| **License:**         | Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
