import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://ldippo.github.io',
  base: '/transcend-harness',
  integrations: [
    starlight({
      title: 'transcend-harness',
      description:
        'A meta-framework that interviews you, detects your stack, and generates a bespoke .claude/ harness.',
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/ldippo/transcend-harness' },
      ],
      editLink: {
        baseUrl: 'https://github.com/ldippo/transcend-harness/edit/main/website/',
      },
      customCss: ['./src/styles/custom.css'],
      sidebar: [
        {
          label: 'Start Here',
          items: [
            { label: 'Getting Started', slug: 'getting-started' },
            { label: 'Philosophy', slug: 'philosophy' },
          ],
        },
        {
          label: 'Concepts',
          items: [
            { label: 'The Six Pillars', autogenerate: { directory: 'pillars' } },
            { label: 'Enforcement Tiers', slug: 'concepts/enforcement-tiers' },
          ],
        },
        {
          label: 'Reference',
          items: [
            { label: 'Skills & Commands', slug: 'reference/skills' },
            { label: 'Agents', slug: 'reference/agents' },
            { label: 'Workflow Catalog', slug: 'reference/catalog' },
          ],
        },
        {
          label: 'Authoring Guides',
          items: [
            { label: 'Authoring Pillars', slug: 'guides/authoring-pillars' },
            { label: 'Authoring Stacks', slug: 'guides/authoring-stacks' },
          ],
        },
        {
          label: 'Internals',
          items: [{ label: 'Architecture', slug: 'internals/architecture' }],
        },
      ],
    }),
  ],
});
