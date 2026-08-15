import type { Theme as ThemeConfig } from "vitepress";
import DefaultTheme from "vitepress/theme";
import { h } from "vue";
import { NolebaseBreadcrumbs } from "@nolebase/vitepress-plugin-breadcrumbs/client";
import "./custom.css";

export default {
  extends: DefaultTheme,
  Layout: () => {
    return h(DefaultTheme.Layout, null, {
      "doc-before": () => h(NolebaseBreadcrumbs),
    });
  },
} satisfies ThemeConfig;
