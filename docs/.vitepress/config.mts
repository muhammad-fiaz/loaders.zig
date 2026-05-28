import { defineConfig } from "vitepress";
import llmstxt from "vitepress-plugin-llms";

type PageData = {
  title?: string;
  description?: string;
  relativePath: string;
  lastUpdated?: number | string | Date;
  frontmatter: {
    description?: string;
    head?: [string, Record<string, string>, string?][];
  };
};

const SITE_URL = "https://muhammad-fiaz.github.io/loaders.zig";
const SITE_NAME = "loaders.zig";
const SITE_DESCRIPTION =
  "High-performance terminal loading indicators and progress bars for Zig.";
const GA_ID = "G-6BVYCRK57P";
const GTM_ID = "GTM-P4M9T8ZR";
const ADSENSE_CLIENT_ID = "ca-pub-2040560600290490";
const KEYWORDS =
  "zig, terminal loading indicators, progress bars, spinners, logging, cli, command line, loading indicator, multi progress, styling, colors, themes, async ui, terminal ui";

export default defineConfig({
  lang: "en-US",
  title: SITE_NAME,
  description: SITE_DESCRIPTION,
  base: "/loaders.zig/",
  lastUpdated: true,
  cleanUrls: true,

  sitemap: {
    hostname: SITE_URL,
  },

  vite: {
    plugins: [llmstxt()],
  },

  head: [
    ["meta", { name: "viewport", content: "width=device-width, initial-scale=1.0" }],
    ["meta", { name: "google-adsense-account", content: ADSENSE_CLIENT_ID }],
    ["meta", { name: "title", content: SITE_NAME }],
    ["meta", { name: "description", content: SITE_DESCRIPTION }],
    ["meta", { name: "keywords", content: KEYWORDS }],
    ["meta", { name: "author", content: "Muhammad Fiaz" }],
    ["meta", { name: "robots", content: "index, follow" }],
    ["meta", { name: "language", content: "English" }],
    ["meta", { name: "revisit-after", content: "7 days" }],
    ["meta", { name: "generator", content: "VitePress" }],
    ["link", { rel: "canonical", href: SITE_URL }],
    ["meta", { property: "og:type", content: "website" }],
    ["meta", { property: "og:url", content: SITE_URL }],
    ["meta", { property: "og:title", content: SITE_NAME }],
    ["meta", { property: "og:description", content: SITE_DESCRIPTION }],
    ["meta", { property: "og:image", content: `${SITE_URL}/cover.png` }],
    ["meta", { property: "og:image:width", content: "1200" }],
    ["meta", { property: "og:image:height", content: "630" }],
    ["meta", { property: "og:image:alt", content: "loaders.zig - High-performance terminal loading indicators for Zig" }],
    ["meta", { property: "og:site_name", content: SITE_NAME }],
    ["meta", { property: "og:locale", content: "en_US" }],
    ["meta", { name: "twitter:card", content: "summary_large_image" }],
    ["meta", { name: "twitter:url", content: SITE_URL }],
    ["meta", { name: "twitter:title", content: SITE_NAME }],
    ["meta", { name: "twitter:description", content: SITE_DESCRIPTION }],
    ["meta", { name: "twitter:image", content: `${SITE_URL}/cover.png` }],
    ["meta", { name: "twitter:creator", content: "@muhammadfiaz_" }],

    ["link", { rel: "icon", href: "/loaders.zig/favicon.ico" }],
    [
      "link",
      {
        rel: "icon",
        type: "image/png",
        sizes: "16x16",
        href: "/loaders.zig/favicon-16x16.png",
      },
    ],
    [
      "link",
      {
        rel: "icon",
        type: "image/png",
        sizes: "32x32",
        href: "/loaders.zig/favicon-32x32.png",
      },
    ],
    [
      "link",
      {
        rel: "apple-touch-icon",
        sizes: "180x180",
        href: "/loaders.zig/apple-touch-icon.png",
      },
    ],
    [
      "link",
      {
        rel: "icon",
        type: "image/png",
        sizes: "192x192",
        href: "/loaders.zig/android-chrome-192x192.png",
      },
    ],
    [
      "link",
      {
        rel: "icon",
        type: "image/png",
        sizes: "512x512",
        href: "/loaders.zig/android-chrome-512x512.png",
      },
    ],
    ["link", { rel: "manifest", href: "/loaders.zig/site.webmanifest" }],
    ["meta", { name: "theme-color", content: "#f7a41d" }],
    ["meta", { name: "msapplication-TileColor", content: "#f7a41d" }],
    [
      "script",
      {
        async: "",
        src: `https://www.googletagmanager.com/gtag/js?id=${GA_ID}`,
      },
    ],
    [
      "script",
      {},
      `window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', '${GA_ID}');`,
    ],
    ...(
      GTM_ID
        ? ([
            [
              "script",
              {},
              `(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start': new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0], j=d.createElement(s), dl=l!='dataLayer'?'&l='+l:''; j.async=true; j.src='https://www.googletagmanager.com/gtm.js?id='+i+dl; f.parentNode.insertBefore(j,f);})(window,document,'script','dataLayer','${GTM_ID}');`,
            ],
            [
              "noscript",
              {},
              `<iframe src="https://www.googletagmanager.com/ns.html?id=${GTM_ID}" height="0" width="0" style="display:none;visibility:hidden"></iframe>`,
            ],
          ] as [string, Record<string, string>, string][])
        : []
    ),
    [
      "script",
      {
        async: "",
        src: `https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${ADSENSE_CLIENT_ID}`,
        crossorigin: "anonymous",
      },
    ],
  ],

  themeConfig: {
    logo: "/loaders.zig/logo.png",
    siteTitle: SITE_NAME,

    nav: [
      { text: "Home", link: "/" },
      { text: "Guide", link: "/guide/" },
      { text: "API", link: "/api/" },
    ],

    sidebar: [
      {
        text: "Overview",
        items: [
          { text: "Guide Overview", link: "/guide/" },
          { text: "API Reference", link: "/api/" },
        ],
      },
      {
        text: "Guides",
        items: [
          { text: "Getting Started", link: "/guide/getting-started" },
          { text: "Progress Bars", link: "/guide/progress-bar" },
          { text: "Spinners", link: "/guide/spinner" },
          { text: "Multi Progress", link: "/guide/multi-progress" },
          { text: "Styling", link: "/guide/styling" },
          { text: "Colors", link: "/guide/colors" },
          { text: "Themes", link: "/guide/themes" },
          { text: "Advanced", link: "/guide/advanced" },
        ],
      },
    ],

    socialLinks: [
      { icon: "github", link: "https://github.com/muhammad-fiaz/loaders.zig" },
    ],

    footer: {
      message: "Released under the MIT License.",
      copyright: `Copyright © 2025-${new Date().getFullYear()} Muhammad Fiaz`,
    },

    search: {
      provider: "local",
    },

    editLink: {
      pattern: "https://github.com/muhammad-fiaz/loaders.zig/edit/main/docs/:path",
      text: "Edit this page on GitHub",
    },

    lastUpdated: {
      text: "Last updated",
      formatOptions: {
        dateStyle: "medium",
        timeStyle: "short",
      },
    },

    outline: {
      level: [2, 3],
      label: "On this page",
    },

    docFooter: {
      prev: "Previous",
      next: "Next",
    },

    returnToTopLabel: "Return to top",
    sidebarMenuLabel: "Menu",
    darkModeSwitchLabel: "Appearance",
  },

  transformPageData(pageData: PageData) {
    const pageTitle = pageData.title || SITE_NAME;
    const pageDescription = pageData.description || SITE_DESCRIPTION;
    const canonicalUrl = `${SITE_URL}/${pageData.relativePath
      .replace(/((^|\/)index)?\.md$/, "$2")
      .replace(/\.md$/, "")}`;

    pageData.frontmatter.head ??= [];
    pageData.frontmatter.head.push(
      ["link", { rel: "canonical", href: canonicalUrl }],
      ["meta", { property: "og:title", content: `${pageTitle} | ${SITE_NAME}` }],
      ["meta", { property: "og:url", content: canonicalUrl }],
      ["meta", { property: "og:description", content: pageDescription }],
      ["meta", { name: "description", content: pageDescription }],
      ["meta", { name: "twitter:title", content: `${pageTitle} | ${SITE_NAME}` }],
      ["meta", { name: "twitter:description", content: pageDescription }],
      ["meta", { name: "twitter:image", content: `${SITE_URL}/cover.png` }],
    );

    if (pageData.frontmatter.description) {
      pageData.frontmatter.head.push(
        ["meta", { property: "og:description", content: pageData.frontmatter.description }],
        ["meta", { name: "description", content: pageData.frontmatter.description }],
        ["meta", { name: "twitter:description", content: pageData.frontmatter.description }],
      );
    }

    const isHome = pageData.relativePath === "index.md";
    const lastUpdated = pageData.lastUpdated
      ? new Date(pageData.lastUpdated).toISOString()
      : new Date().toISOString();

    const graph: Record<string, unknown>[] = [];

    if (isHome) {
      graph.push({
        "@type": "WebSite",
        name: SITE_NAME,
        url: SITE_URL,
        description: SITE_DESCRIPTION,
        author: {
          "@type": "Person",
          name: "Muhammad Fiaz",
          url: "https://github.com/muhammad-fiaz",
        },
      });
    }

    const authorSchema = {
      "@type": "Person",
      name: "Muhammad Fiaz",
      url: "https://muhammadfiaz.com",
      sameAs: [
        "https://github.com/muhammad-fiaz",
        "https://www.linkedin.com/in/muhammad-fiaz-",
        "https://x.com/muhammadfiaz_",
      ],
    };

    const primarySchema: Record<string, unknown> = {
      "@type": isHome ? "SoftwareApplication" : "TechArticle",
      name: isHome ? SITE_NAME : pageTitle,
      description: pageDescription,
      url: canonicalUrl,
      image: `${SITE_URL}/cover.png`,
      author: authorSchema,
      publisher: {
        "@type": "Organization",
        name: SITE_NAME,
        url: SITE_URL,
        logo: {
          "@type": "ImageObject",
          url: `${SITE_URL}/logo.png`,
        },
      },
    };

    if (isHome) {
      Object.assign(primarySchema, {
        applicationCategory: "DeveloperApplication",
        operatingSystem: "Cross-platform",
        programmingLanguage: "Zig",
        offers: {
          "@type": "Offer",
          price: "0",
          priceCurrency: "USD",
        },
        downloadUrl: "https://github.com/muhammad-fiaz/loaders.zig",
        license: "https://opensource.org/licenses/MIT",
      });
    } else {
      const pathParts: string[] = String(pageData.relativePath).split("/");
      const section =
        pathParts.length > 1
          ? pathParts[0].charAt(0).toUpperCase() + pathParts[0].slice(1)
          : "Documentation";

      Object.assign(primarySchema, {
        headline: pageTitle,
        articleSection: section,
        mainEntityOfPage: {
          "@type": "WebPage",
          "@id": canonicalUrl,
        },
        datePublished: "2025-01-01T00:00:00Z",
        dateModified: lastUpdated,
      });
    }

    graph.push(primarySchema);

    const breadcrumbs: Record<string, unknown>[] = [
      {
        "@type": "ListItem",
        position: 1,
        name: "Home",
        item: SITE_URL,
      },
    ];

    if (!isHome) {
      const pathParts: string[] = String(pageData.relativePath).replace(/\.md$/, "").split("/");
      let currentPath = SITE_URL;

      pathParts.forEach((part: string, index: number) => {
        currentPath += `/${part}`;
        const name = part
          .split("-")
          .map((s: string) => s.charAt(0).toUpperCase() + s.slice(1))
          .join(" ");

        breadcrumbs.push({
          "@type": "ListItem",
          position: index + 2,
          name,
          item: index === pathParts.length - 1 ? canonicalUrl : currentPath,
        });
      });
    }

    graph.push({
      "@type": "BreadcrumbList",
      itemListElement: breadcrumbs,
    });

    pageData.frontmatter.head.push([
      "script",
      { type: "application/ld+json" },
      JSON.stringify({
        "@context": "https://schema.org",
        "@graph": graph,
      }),
    ]);
  },
});
