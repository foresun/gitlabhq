---
comments: false
type: index, howto
---

# Migrating from CircleCI

If you are currently using CircleCI, you can migrate your CI/CD pipelines to [GitLab CI/CD](../introduction/index.md),
and start making use of all its powerful features. Check out our
[CircleCI vs GitLab](https://about.gitlab.com/devops-tools/circle-ci-vs-gitlab.html)
comparison to see what's different.

We have collected several resources that you may find useful before starting to migrate.

The [Quick Start Guide](../quick_start/README.md) is a good overview of how GitLab CI/CD works. You may also be interested in [Auto DevOps](../../topics/autodevops/index.md) which can be used to build, test, and deploy your applications with little to no configuration needed at all.

For advanced CI/CD teams, [custom project templates](../../user/admin_area/custom_project_templates.md) can enable the reuse of pipeline configurations.

If you have questions that are not answered here, the [GitLab community forum](https://forum.gitlab.com/) can be a great resource.

## `config.yml` vs `gitlab-ci.yml`

CircleCI's `config.yml` configuration file defines scripts, jobs, and workflows (known as "stages" in GitLab). In GitLab, a similar approach is used with a `.gitlab-ci.yml` file in the root directory of your repository.

### Jobs

In CircleCI, jobs are a collection of steps to perform a specific task. In GitLab, [jobs](../yaml/README.md#introduction) are also a fundamental element in the configuration file. The `checkout` parameter is not necessary in GitLab CI/CD as the repository is automatically fetched.

CircleCI example job definition:

```yaml
jobs:
  job1:
    steps:
      - checkout
      - run: "execute-script-for-job1"
```

Example of the same job definition in GitLab CI/CD:

``` yaml
job1:
  script: "execute-script-for-job1"
```

### Docker image definition

CircleCI defines images at the job level, which is also supported by GitLab CI/CD. Additionally, GitLab CI/CD supports setting this globally to be used by all jobs that don't have `image` defined.

CircleCI example image definition:

```yaml
jobs:
  job1:
    docker:
      - image: ruby:2.6
```

Example of the same image definition in GitLab CI/CD:

```yaml
job1:
  image: ruby:2.6
```

### Workflows

CircleCI determines the run order for jobs with `workflows`. This is also used to determine concurrent, sequential, scheduled, or manual runs. The equivalent function in GitLab CI/CD is called [stages](../yaml/README.md#stages). Jobs on the same stage run in parallel, and only run after previous stages complete. Execution of the next stage is skipped when a job fails by default, but this can be allowed to continue even [after a failed job](../yaml/README.md#allow_failure).

See [the Pipeline Architecture Overview](../pipelines/pipeline_architectures.md) for guidance on different types of pipelines that you can use. Pipelines can be tailored to meet your needs, such as for a large complex project or a monorepo with independent defined components.

#### Parallel and sequential job execution

The following examples show how jobs can run in parallel, or sequentially:

1. `job1` and `job2` run in parallel (in the `build` stage for GitLab CI/CD).
1. `job3` runs only after `job1` and `job2` complete successfully (in the `test` stage).
1. `job4` runs only after `job3` completes successfully (in the `deploy` stage).

CircleCI example with `workflows`:

```yaml
version: 2
jobs:
  job1:
    steps:
      - checkout
      - run: make build dependencies
  job2:
    steps:
      - run: make build artifacts
  job3:
    steps:
      - run: make test
  job4:
    steps:
      - run: make deploy

workflows:
  version: 2
  jobs:
    - job1
    - job2
    - job3:
        requires:
          - job1
          - job2
    - job4:
        requires:
          - job3
```

Example of the same workflow as `stages` in GitLab CI/CD:

```yaml
stages:
  - build
  - test
  - deploy
  
job 1:
  stage: build
  script: make build dependencies

job 2:
  stage: build
  script: make build artifacts
  
job3:
  stage: test
  script: make test

job4:
  stage: deploy
  script: make deploy
```

#### Scheduled run

GitLab CI/CD has an easy to use UI to [schedule pipelines](../pipelines/schedules.md). Also, [rules](../yaml/README.md#rules) can be used to determine if jobs should be included or excluded from a scheduled pipeline.

CircleCI example of a scheduled workflow:

```yaml
commit-workflow:
  jobs:
    - build
scheduled-workflow:
  triggers:
    - schedule:
        cron: "0 1 * * *"
        filters:
          branches:
            only: try-schedule-workflow
  jobs:
    - build
```

Example of the same scheduled pipeline using [`rules`](../yaml/README.md#rules) in GitLab CI/CD:

```yaml
job1:
  script:
    - make build
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule" && $CI_COMMIT_REF_NAME == "try-schedule-workflow"'
```

After the pipeline configuration is saved, you configure the cron schedule in the [GitLab UI](../pipelines/schedules.md#configuring-pipeline-schedules), and can enable or disable schedules in the UI as well.

#### Manual run

CircleCI example of a manual workflow:

```yaml
release-branch-workflow:
  jobs:
    - build
    - testing:
        requires:
          - build
    - deploy:
        type: approval
        requires:
          - testing
```

Example of the same workflow using [`when: manual`](../yaml/README.md#whenmanual) in GitLab CI/CD:

```yaml
deploy_prod:
  stage: deploy
  script:
    - echo "Deploy to production server"
  when: manual
```

### Filter job by branch

[Rules](../yaml/README.md#rules) are a mechanism to determine if the job will or will not run for a specific branch.

CircleCI example of a job filtered by branch:

```yaml
jobs:
  deploy:
    branches:
      only:
        - master
        - /rc-.*/
```

Example of the same workflow using `rules` in GitLab CI/CD:

```yaml
deploy_prod:
  stage: deploy
  script:
    - echo "Deploy to production server"
  rules:
    - if: '$CI_COMMIT_BRANCH == "master"'
```

### Caching

GitLab provides a caching mechanism to speed up build times for your jobs by reusing previously downloaded dependencies. It's important to know the different between [cache and artifacts](../caching/index.md#cache-vs-artifacts) to make the best use of these features.

CircleCI example of a job using a cache:

```yaml
jobs:
  job1:
    steps:
      - restore_cache:
          key: source-v1-< .Revision >
      - checkout
      - run: npm install
      - save_cache:
          key: source-v1-< .Revision >
          paths:
            - "node_modules"
```

Example of the same pipeline using `cache` in GitLab CI/CD:

```yaml
image: node:latest

# Cache modules in between jobs
cache:
  key: $CI_COMMIT_REF_SLUG
  paths:
    - .npm/

before_script:
  - npm ci --cache .npm --prefer-offline

test_async:
  script:
    - node ./specs/start.js ./specs/async.spec.js
```

## Contexts and variables

CircleCI provides [Contexts](https://circleci.com/docs/2.0/contexts/) to securely pass environment variables across project pipelines. In GitLab, a [Group](../../user/group/index.md) can be created to assemble related projects together. At the group level, [variables](../variables/README.md#group-level-environment-variables) can be stored outside the individual projects, and securely passed into pipelines across multiple projects.

## Orbs

There are two GitLab issues open addressing CircleCI Orbs and how GitLab can achieve similar functionality.

- <https://gitlab.com/gitlab-com/Product/-/issues/1151>
- <https://gitlab.com/gitlab-org/gitlab/-/issues/195173>

## Build environments

CircleCI offers `executors` as the underlying technology to run a specific job. In GitLab, this is done by [Runners](https://docs.gitlab.com/runner/).

The following environments are supported:

Self-Managed Runners:

- Linux
- Windows
- macOS

GitLab.com Shared Runners:

- Linux
- Windows
- [Planned: macOS](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/5720)

### Machine and specific build environments

[Tags](../yaml/README.md#tags) can be used to run jobs on different platforms, by telling GitLab which Runners should run the jobs.

CircleCI example of a job running on a specific environment:

```yaml
jobs:
  ubuntuJob:
    machine:
      image: ubuntu-1604:201903-01
    steps:
      - checkout
      - run: echo "Hello, $USER!"
  osxJob:
    macos:
      xcode: 11.3.0
    steps:
      - checkout
      - run: echo "Hello, $USER!"
```

Example of the same job using `tags` in GitLab CI/CD:

```yaml
windows job:
  stage:
    - build
  tags:
    - windows
  script:
    - echo Hello, %USERNAME%!

osx job:
  stage:
    - build
  tags:
    - osx
  script:
    - echo "Hello, $USER!"
```