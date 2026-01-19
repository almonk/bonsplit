"use client";

import { Highlight, themes, Prism } from "prism-react-renderer";

// Add Swift language support to Prism
(typeof global !== "undefined" ? global : window).Prism = Prism;
require("prismjs/components/prism-swift");

interface CodeBlockProps {
  children: string;
  language?: string;
  showLineNumbers?: boolean;
}

export default function CodeBlock({ children, language = "swift", showLineNumbers = false }: CodeBlockProps) {
  const code = children.trim();

  return (
    <div className="rounded-lg overflow-hidden">
      <Highlight
        theme={themes.dracula}
        code={code}
        language={language}
      >
        {({ className, style, tokens, getLineProps, getTokenProps }) => (
          <pre
            className={`${className} p-4 overflow-x-auto font-mono`}
            style={{
              ...style,
              backgroundColor: "rgba(255,255,255,0.03)",
              margin: 0,
              fontSize: "13px",
            }}
          >
            {tokens.map((line, i) => {
              const { key: __, className: lineClassName, ...lineProps } = getLineProps({ line, key: i });
              return (
                <div key={i} {...lineProps} className={`${lineClassName || ""} table-row`}>
                  {showLineNumbers && (
                    <span className="table-cell pr-4 text-[#666] select-none text-right w-8">
                      {i + 1}
                    </span>
                  )}
                  <span className="table-cell">
                    {line.map((token, tokenIndex) => {
                      const { key: _, ...tokenProps } = getTokenProps({ token, key: tokenIndex });
                      return <span key={tokenIndex} {...tokenProps} />;
                    })}
                  </span>
                </div>
              );
            })}
          </pre>
        )}
      </Highlight>
    </div>
  );
}

// Inline code component
export function InlineCode({ children }: { children: React.ReactNode }) {
  return (
    <code className="bg-[#2a2a2a] px-1.5 py-0.5 rounded text-sm font-mono text-[#e06c75]">
      {children}
    </code>
  );
}
