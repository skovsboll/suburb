# Suburb


### The developer friendly build graph

A build tool that connects other build tools with a complete and acyclic graph.
Unline many other build tools, Suburb does not try to take over the world but lets you work,
directly in your code repo, using the tools that you love.



### A taste of Suburb


Imagine you have a repo where you want to use a tool, say `openapi-generator-cli` and zip it up.

Build definitions live in files called `subu.rb`. In this one, two output files are declared. They are connected through the `ins:` named argument.


`subu.rb`: (&larr; the build definition file)
```ruby
file 'out/A.txt' do
  sh 'touch out/A.txt'
end

file 'out/B.txt', ins: 'out/A.txt' do
  sh 'touch out/B.txt'
end
```


### Another example mixing shell and Ruby code:

`subu.rb`: (&larr; the build definition file)
```ruby
file 'app.zip', ins: ['generated_code/api.rb', 'manifest.md'] do |ins, outs|
  sh "zip #{outs[0]} #{ins.join(' ')}"

file 'generated_code/api.rb', ins: 'api.yaml' do |ins, outs|
  File.write(outs[0], 
    "require 'sinatra'\n" +
      File.readlines(ins[0]).map(&:strip).map { 
        "get '#{_1}' { [200, {}, 'hello from #{_1}'] }" 
      }.join("\n")
  )
end
```

Now, at the root, you can say:

```bash

suburb app.zip

# ┌ Building out/app.zip ▣▣
# └── generated_code/api.rb
# └── out/app.zip
# ℹ info    Completed in 7 ms.
# ℹ info    Log file: cat ./suburb.log

```


## Reasons for Suburb

Makefiles and Rakefiles are easy to read and understand. 
They have two flaws though: 1) They require the entire graph to be specified in one (M/R)akefile. While you can invoke one from another, there is no tree/graph of targets and their dependencies.

Bazel has good tool isolation, great build dependency isolation, predictable builds and caching.

Docker buildx and bake has easy to understand Dockerfiles and great tool isolation during build. But it has a mediocre concept of complete build graphs (additional_contexts). It has OK caching, based on checksums but made with the concept of layers instead of a true tree. 

Vite, rollup, ESBuild and that lot are great at Typescript and Javascript projects, but that's all they do. Time to build Rust or C++ and you have to look elsewhere anyway.


## What Suburb does differently

**Acyclic Build Graph**
Provides an way of **connecting different build systems** into one, coherent graph.
A build definition allows declaring output files, input files and recipe to build a target. 

**Files, files, files**
All targets are files. No phony targets (Make), not task targets (Rake), no _test_ or _run_ targets (Bazel).

**Caches results.** 
For now, caches by file modification time. In the future, by file fingerprint/hash.
Uses your project folders instead of relocating building to some exoctic temp dir. This also makes source maps and debug symbols point to your actual source locations. How nice is that? 

**Only does one thing well.** 
Relies on toolchain managers for what they are good at. Integrates by default with [RTX]() but you can choose another tools manager or install prerequisites and tools manually. 
Relies on package managers for what they are good at. If a subproject is full of Rust code, use Cargo. If it's a web app, use Vite.

**Non invasive.** 
You can still work on your local machine like you are used to. Run `pnpm run dev` or `rails s` or `cmake ..` without limitations.



## Why the name?

**Su**per **Bu**ild 

Build definition files are named subu.rb. I wanted build definitions to end with .rb so editors can highlight and understand the ruby code.