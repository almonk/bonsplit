"use client";

import { useState, useEffect } from "react";
import CodeBlock from "./CodeBlock";

const sections = [
  { id: "installation", label: "Installation" },
  { id: "features", label: "Features" },
  { id: "api-reference", label: "Reference" },
];

const APIExample = ({
  title,
  code,
  description,
  icon,
}: {
  title: string;
  code: string;
  description: string;
  icon: React.ReactNode;
}) => (
  <div className="grid grid-cols-[24px_2fr_3fr] gap-8">
    <div className="text-[#999] dark:text-[#666]">{icon}</div>
    <div>
      <h4 className="text-[15px] font-semibold text-[#333] dark:text-[#eee]">
        {title}
      </h4>
      <p className="text-[15px] text-[#666] dark:text-[#999]">{description}</p>
    </div>
    <div>
      <CodeBlock>{code}</CodeBlock>
    </div>
  </div>
);

// API Reference Components
const MethodSignature = ({ children }: { children: string }) => (
  <code className="block bg-[#f8f9fa] dark:bg-[#111] px-4 py-3 rounded-md font-mono text-[13px] text-[#333] dark:text-[#ddd] whitespace-pre-wrap">
    {children}
  </code>
);

const Parameter = ({
  name,
  type,
  description,
  optional = false,
  defaultValue,
}: {
  name: string;
  type: string;
  description: string;
  optional?: boolean;
  defaultValue?: string;
}) => (
  <div className="flex gap-4 py-2.5">
    <div className="w-36 shrink-0">
      <code className="text-[13px] font-mono text-[#e06c75]">{name}</code>
      {optional && (
        <span className="text-[11px] text-[#888] ml-1.5">optional</span>
      )}
    </div>
    <div className="flex-1">
      <code className="text-[12px] font-mono text-[#888]">{type}</code>
      <p className="text-[14px] text-[#666] dark:text-[#999] mt-0.5 leading-relaxed">
        {description}
      </p>
      {defaultValue && (
        <p className="text-[12px] text-[#888] mt-1">
          Default: <code className="text-[#e06c75]">{defaultValue}</code>
        </p>
      )}
    </div>
  </div>
);

const ReturnValue = ({
  type,
  description,
}: {
  type: string;
  description: string;
}) => (
  <div className="mt-5 py-3 px-4 bg-[#f8f9fa] dark:bg-[#111] rounded-md">
    <div className="text-[11px] font-medium text-[#888] uppercase tracking-wider mb-1.5">
      Returns
    </div>
    <code className="text-[13px] font-mono text-[#e06c75]">{type}</code>
    <p className="text-[14px] text-[#666] dark:text-[#999] mt-0.5 leading-relaxed">
      {description}
    </p>
  </div>
);

const APIMethod = ({
  name,
  signature,
  description,
  parameters,
  returnValue,
  example,
}: {
  name: string;
  signature: string;
  description: string;
  parameters?: {
    name: string;
    type: string;
    description: string;
    optional?: boolean;
    defaultValue?: string;
  }[];
  returnValue?: { type: string; description: string };
  example?: string;
}) => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="w-full flex items-center gap-2.5 text-left py-2 -mx-2 px-2 rounded hover:bg-[#f5f5f5] dark:hover:bg-[#1a1a1a] transition-colors"
      >
        <svg
          className={`w-3 h-3 text-[#bbb] dark:text-[#666] transition-transform shrink-0 ${isOpen ? "rotate-90" : ""}`}
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth={2.5}
        >
          <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
        </svg>
        <code className="text-[14px] font-mono font-normal text-[#333] dark:text-[#eee]">
          {name}
        </code>
      </button>
      {isOpen && (
        <div className="pt-3 pb-6 ml-[22px]">
          <MethodSignature>{signature}</MethodSignature>
          <p className="text-[14px] text-[#666] dark:text-[#999] mt-3 leading-relaxed">
            {description}
          </p>
          {parameters && parameters.length > 0 && (
            <div className="mt-5">
              <div className="text-[11px] font-medium text-[#888] uppercase tracking-wider mb-2">
                Parameters
              </div>
              <div className="bg-[#f8f9fa] dark:bg-[#111] rounded-md py-1 px-4">
                {parameters.map((param, i) => (
                  <Parameter key={i} {...param} />
                ))}
              </div>
            </div>
          )}
          {returnValue && <ReturnValue {...returnValue} />}
          {example && (
            <div className="mt-5">
              <div className="text-[11px] font-medium text-[#888] uppercase tracking-wider mb-2">
                Example
              </div>
              <CodeBlock>{example}</CodeBlock>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

const APISection = ({
  title,
  id,
  children,
}: {
  title: string;
  id: string;
  children: React.ReactNode;
}) => (
  <div id={id} className="scroll-mt-8">
    <h3 className="text-[20px] font-semibold text-[#333] dark:text-[#eee] mb-1">
      {title}
    </h3>
    {children}
  </div>
);

const CategoryHeader = ({ children }: { children: string }) => (
  <div className="text-[12px] font-medium text-[#888] uppercase tracking-wider mt-8 mb-3">
    {children}
  </div>
);

const TypeDefinition = ({
  name,
  definition,
  description,
}: {
  name: string;
  definition: string;
  description: string;
}) => (
  <div className="py-4">
    <h4 className="text-[16px] font-medium text-[#333] dark:text-[#eee] mb-2">
      {name}
    </h4>
    <p className="text-[14px] text-[#666] dark:text-[#999] mb-4 leading-relaxed">
      {description}
    </p>
    <CodeBlock>{definition}</CodeBlock>
  </div>
);

const DelegateMethod = ({
  name,
  signature,
  description,
}: {
  name: string;
  signature: string;
  description: string;
}) => (
  <div className="py-3">
    <code className="text-[13px] font-mono text-[#e06c75]">{name}</code>
    <p className="text-[14px] text-[#666] dark:text-[#999] mt-1.5 leading-relaxed">
      {description}
    </p>
    <code className="block text-[12px] font-mono text-[#888] mt-1.5 leading-relaxed">
      {signature}
    </code>
  </div>
);

export default function ContentSections() {
  const [activeSection, setActiveSection] = useState("installation");

  useEffect(() => {
    const observers: IntersectionObserver[] = [];

    sections.forEach(({ id }) => {
      const element = document.getElementById(id);
      if (element) {
        const observer = new IntersectionObserver(
          (entries) => {
            entries.forEach((entry) => {
              if (entry.isIntersecting) {
                setActiveSection(id);
              }
            });
          },
          { rootMargin: "-40px 0px -60% 0px", threshold: 0 },
        );
        observer.observe(element);
        observers.push(observer);
      }
    });

    return () => {
      observers.forEach((observer) => observer.disconnect());
    };
  }, []);

  return (
    <div className="lg:grid lg:grid-cols-12 lg:gap-8 py-16">
      {/* Main content - 11 columns */}
      <div className="lg:col-span-11 space-y-24">
        {/* Features */}
        <section id="features">
          <div className="mb-12">
            <p className="font-mono text-[14px] text-[#999] dark:text-[#666] mb-2">
              ### Features
            </p>
            <h2 className="text-[32px] font-semibold text-[#333] dark:text-[#eee]">
              Configurable &amp; Observable
            </h2>
          </div>

          <div className="grid grid-cols-1 gap-8">
            <APIExample
              title="Create Tabs"
              description="Create tabs with optional icons and dirty indicators. Target specific panes or use the focused pane."
              icon={
                <svg
                  className="w-5 h-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={1.5}
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M12 4.5v15m7.5-7.5h-15"
                  />
                </svg>
              }
              code={`let tabId = controller.createTab(
    title: "Document.swift",
    icon: "swift",
    isDirty: false,
    inPane: paneId
)`}
            />
            <APIExample
              title="Split Panes"
              description="Split any pane horizontally or vertically. New panes are empty by default, giving you full control."
              icon={
                <svg
                  className="w-5 h-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={1.5}
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M9 4.5v15m6-15v15M4.5 4.5h15v15h-15z"
                  />
                </svg>
              }
              code={`// Split focused pane horizontally
let newPaneId = controller.splitPane(
    orientation: .horizontal
)

// Split with a tab already in the new pane
controller.splitPane(
    orientation: .vertical,
    withTab: Tab(title: "New", icon: "doc")
)`}
            />
            <APIExample
              title="Update Tab State"
              description="Update tab properties at any time. Changes animate smoothly."
              icon={
                <svg
                  className="w-5 h-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={1.5}
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931z"
                  />
                </svg>
              }
              code={`// Mark document as modified
controller.updateTab(tabId, isDirty: true)

// Rename tab
controller.updateTab(tabId, title: "NewName.swift")

// Change icon
controller.updateTab(tabId, icon: "doc.text")`}
            />
            <APIExample
              title="Navigate Focus"
              description="Programmatically navigate between panes using directional navigation."
              icon={
                <svg
                  className="w-5 h-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={1.5}
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M3.75 3.75v4.5m0-4.5h4.5m-4.5 0L9 9M3.75 20.25v-4.5m0 4.5h4.5m-4.5 0L9 15M20.25 3.75h-4.5m4.5 0v4.5m0-4.5L15 9m5.25 11.25h-4.5m4.5 0v-4.5m0 4.5L15 15"
                  />
                </svg>
              }
              code={`// Move focus between panes
controller.navigateFocus(direction: .left)
controller.navigateFocus(direction: .right)
controller.navigateFocus(direction: .up)
controller.navigateFocus(direction: .down)

// Or focus a specific pane
controller.focusPane(paneId)`}
            />
          </div>
        </section>

        {/* API Reference */}
        <section id="api-reference">
          <div className="mb-12">
            <p className="font-mono text-[14px] text-[#999] dark:text-[#666] mb-2">
              ### Read this, agents...
            </p>
            <h2 className="text-[32px] font-semibold text-[#333] dark:text-[#eee]">
              API Reference
            </h2>
            <p className="text-lg text-[#666] dark:text-[#999] mt-4">
              Complete reference for all Bonsplit classes, methods, and
              configuration options.
            </p>
          </div>

          <div className="space-y-12">
            {/* BonsplitController */}
            <APISection title="BonsplitController" id="bonsplit-controller">
              <p className="text-[14px] text-[#666] dark:text-[#999] mt-2 mb-4 leading-relaxed">
                The main controller for managing tabs and panes. Create an
                instance and pass it to BonsplitView.
              </p>

              <CategoryHeader>Tab Operations</CategoryHeader>

              <APIMethod
                name="createTab"
                signature="func createTab(title: String, icon: String?, isDirty: Bool, inPane: PaneID?) -> TabID?"
                description="Creates a new tab in the specified pane, or the focused pane if none is specified. Returns the new tab's ID, or nil if creation was prevented by the delegate."
                parameters={[
                  {
                    name: "title",
                    type: "String",
                    description: "The display title for the tab",
                  },
                  {
                    name: "icon",
                    type: "String?",
                    description: "SF Symbol name for the tab icon",
                    optional: true,
                  },
                  {
                    name: "isDirty",
                    type: "Bool",
                    description: "Whether to show a dirty/unsaved indicator",
                    optional: true,
                    defaultValue: "false",
                  },
                  {
                    name: "inPane",
                    type: "PaneID?",
                    description:
                      "Target pane for the tab. Uses focused pane if nil",
                    optional: true,
                  },
                ]}
                returnValue={{
                  type: "TabID?",
                  description:
                    "The unique identifier for the created tab, or nil if creation was prevented",
                }}
                example={`let tabId = controller.createTab(
    title: "Document.swift",
    icon: "swift",
    isDirty: false,
    inPane: paneId
)`}
              />

              <APIMethod
                name="updateTab"
                signature="func updateTab(_ id: TabID, title: String?, icon: String?, isDirty: Bool?)"
                description="Updates properties of an existing tab. Only non-nil parameters are updated. Changes animate smoothly."
                parameters={[
                  {
                    name: "id",
                    type: "TabID",
                    description: "The tab to update",
                  },
                  {
                    name: "title",
                    type: "String?",
                    description: "New title for the tab",
                    optional: true,
                  },
                  {
                    name: "icon",
                    type: "String?",
                    description: "New SF Symbol name for the icon",
                    optional: true,
                  },
                  {
                    name: "isDirty",
                    type: "Bool?",
                    description: "New dirty state",
                    optional: true,
                  },
                ]}
                example={`controller.updateTab(tabId, title: "NewName.swift")
controller.updateTab(tabId, isDirty: true)`}
              />

              <APIMethod
                name="closeTab"
                signature="func closeTab(_ id: TabID)"
                description="Closes the specified tab. The delegate's shouldCloseTab method is called first, allowing you to prevent closure or prompt the user to save."
                parameters={[
                  {
                    name: "id",
                    type: "TabID",
                    description: "The tab to close",
                  },
                ]}
              />

              <APIMethod
                name="selectTab"
                signature="func selectTab(_ id: TabID)"
                description="Selects the specified tab, making it the active tab in its pane."
                parameters={[
                  {
                    name: "id",
                    type: "TabID",
                    description: "The tab to select",
                  },
                ]}
              />

              <APIMethod
                name="selectPreviousTab / selectNextTab"
                signature="func selectPreviousTab()\nfunc selectNextTab()"
                description="Cycles through tabs in the focused pane. Wraps around at the ends."
              />

              <CategoryHeader>Split Operations</CategoryHeader>

              <APIMethod
                name="splitPane"
                signature="func splitPane(_ pane: PaneID?, orientation: SplitOrientation, withTab: Tab?) -> PaneID?"
                description="Splits a pane horizontally or vertically. By default creates an empty pane, giving you full control over when to add tabs. Use the didSplitPane delegate to auto-create tabs."
                parameters={[
                  {
                    name: "pane",
                    type: "PaneID?",
                    description: "The pane to split. Uses focused pane if nil",
                    optional: true,
                  },
                  {
                    name: "orientation",
                    type: "SplitOrientation",
                    description:
                      ".horizontal (side-by-side) or .vertical (stacked)",
                  },
                  {
                    name: "withTab",
                    type: "Tab?",
                    description: "Optional tab to create in the new pane",
                    optional: true,
                  },
                ]}
                returnValue={{
                  type: "PaneID?",
                  description:
                    "The new pane's ID, or nil if split was prevented",
                }}
                example={`// Split horizontally (side-by-side)
let newPaneId = controller.splitPane(orientation: .horizontal)

// Split vertically (stacked) with a new tab
controller.splitPane(
    orientation: .vertical,
    withTab: Tab(title: "New", icon: "doc")
)`}
              />

              <APIMethod
                name="closePane"
                signature="func closePane(_ id: PaneID)"
                description="Closes the specified pane and all its tabs. The delegate's shouldClosePane method is called first."
                parameters={[
                  {
                    name: "id",
                    type: "PaneID",
                    description: "The pane to close",
                  },
                ]}
              />

              <CategoryHeader>Focus Management</CategoryHeader>

              <APIMethod
                name="focusedPaneId"
                signature="var focusedPaneId: PaneID? { get }"
                description="Returns the currently focused pane's ID."
                returnValue={{
                  type: "PaneID?",
                  description: "The focused pane's identifier",
                }}
              />

              <APIMethod
                name="focusPane"
                signature="func focusPane(_ id: PaneID)"
                description="Sets focus to the specified pane."
                parameters={[
                  {
                    name: "id",
                    type: "PaneID",
                    description: "The pane to focus",
                  },
                ]}
              />

              <APIMethod
                name="navigateFocus"
                signature="func navigateFocus(direction: NavigationDirection)"
                description="Moves focus to an adjacent pane in the specified direction."
                parameters={[
                  {
                    name: "direction",
                    type: "NavigationDirection",
                    description: ".left, .right, .up, or .down",
                  },
                ]}
                example={`controller.navigateFocus(direction: .left)
controller.navigateFocus(direction: .right)
controller.navigateFocus(direction: .up)
controller.navigateFocus(direction: .down)`}
              />

              <CategoryHeader>Query Methods</CategoryHeader>

              <APIMethod
                name="allTabIds"
                signature="var allTabIds: [TabID] { get }"
                description="Returns all tab IDs across all panes."
                returnValue={{
                  type: "[TabID]",
                  description: "Array of all tab identifiers",
                }}
              />

              <APIMethod
                name="allPaneIds"
                signature="var allPaneIds: [PaneID] { get }"
                description="Returns all pane IDs."
                returnValue={{
                  type: "[PaneID]",
                  description: "Array of all pane identifiers",
                }}
              />

              <APIMethod
                name="tab"
                signature="func tab(_ id: TabID) -> Tab?"
                description="Returns a read-only snapshot of a tab's current state."
                parameters={[
                  {
                    name: "id",
                    type: "TabID",
                    description: "The tab to query",
                  },
                ]}
                returnValue={{
                  type: "Tab?",
                  description: "Tab snapshot, or nil if not found",
                }}
                example={`if let tab = controller.tab(tabId) {
    print(tab.title, tab.icon, tab.isDirty)
}`}
              />

              <APIMethod
                name="tabs(inPane:)"
                signature="func tabs(inPane id: PaneID) -> [Tab]"
                description="Returns all tabs in a specific pane."
                parameters={[
                  {
                    name: "id",
                    type: "PaneID",
                    description: "The pane to query",
                  },
                ]}
                returnValue={{
                  type: "[Tab]",
                  description: "Array of tabs in the pane",
                }}
              />

              <APIMethod
                name="selectedTab(inPane:)"
                signature="func selectedTab(inPane id: PaneID) -> Tab?"
                description="Returns the currently selected tab in a pane."
                parameters={[
                  {
                    name: "id",
                    type: "PaneID",
                    description: "The pane to query",
                  },
                ]}
                returnValue={{
                  type: "Tab?",
                  description: "The selected tab, or nil if pane is empty",
                }}
              />
            </APISection>

            {/* BonsplitDelegate */}
            <APISection title="BonsplitDelegate" id="bonsplit-delegate">
              <p className="text-[14px] text-[#666] dark:text-[#999] mt-2 mb-4 leading-relaxed">
                Implement this protocol to receive callbacks about tab bar
                events. All methods have default implementations and are
                optional.
              </p>

              <CategoryHeader>Tab Callbacks</CategoryHeader>

              <APIMethod
                name="shouldCreateTab"
                signature="func splitTabBar(_ controller: BonsplitController, shouldCreateTab tab: Tab, inPane pane: PaneID) -> Bool"
                description="Called before creating a tab. Return false to prevent creation."
                returnValue={{
                  type: "Bool",
                  description: "Return true to allow, false to prevent",
                }}
              />
              <APIMethod
                name="didCreateTab"
                signature="func splitTabBar(_ controller: BonsplitController, didCreateTab tab: Tab, inPane pane: PaneID)"
                description="Called after a tab is created."
              />
              <APIMethod
                name="shouldCloseTab"
                signature="func splitTabBar(_ controller: BonsplitController, shouldCloseTab tab: Tab, inPane pane: PaneID) -> Bool"
                description="Called before closing a tab. Return false to prevent closure (e.g., to prompt user to save)."
                returnValue={{
                  type: "Bool",
                  description: "Return true to allow, false to prevent",
                }}
                example={`func splitTabBar(_ controller: BonsplitController,
                 shouldCloseTab tab: Tab,
                 inPane pane: PaneID) -> Bool {
    if tab.isDirty {
        return showSaveConfirmation()
    }
    return true
}`}
              />
              <APIMethod
                name="didCloseTab"
                signature="func splitTabBar(_ controller: BonsplitController, didCloseTab tabId: TabID, fromPane pane: PaneID)"
                description="Called after a tab is closed. Use this to clean up associated data."
              />
              <APIMethod
                name="didSelectTab"
                signature="func splitTabBar(_ controller: BonsplitController, didSelectTab tab: Tab, inPane pane: PaneID)"
                description="Called when a tab is selected."
              />
              <APIMethod
                name="didMoveTab"
                signature="func splitTabBar(_ controller: BonsplitController, didMoveTab tab: Tab, fromPane: PaneID, toPane: PaneID)"
                description="Called when a tab is moved between panes via drag-and-drop."
              />

              <CategoryHeader>Pane Callbacks</CategoryHeader>

              <APIMethod
                name="shouldSplitPane"
                signature="func splitTabBar(_ controller: BonsplitController, shouldSplitPane pane: PaneID, orientation: SplitOrientation) -> Bool"
                description="Called before creating a split. Return false to prevent."
                returnValue={{
                  type: "Bool",
                  description: "Return true to allow, false to prevent",
                }}
              />
              <APIMethod
                name="didSplitPane"
                signature="func splitTabBar(_ controller: BonsplitController, didSplitPane originalPane: PaneID, newPane: PaneID, orientation: SplitOrientation)"
                description="Called after a split is created. New panes are empty by default—use this to auto-create a tab if desired."
                example={`func splitTabBar(_ controller: BonsplitController,
                 didSplitPane originalPane: PaneID,
                 newPane: PaneID,
                 orientation: SplitOrientation) {
    // Auto-create a tab in the new pane
    controller.createTab(title: "Untitled", inPane: newPane)
}`}
              />
              <APIMethod
                name="shouldClosePane"
                signature="func splitTabBar(_ controller: BonsplitController, shouldClosePane pane: PaneID) -> Bool"
                description="Called before closing a pane. Return false to prevent."
                returnValue={{
                  type: "Bool",
                  description: "Return true to allow, false to prevent",
                }}
              />
              <APIMethod
                name="didClosePane"
                signature="func splitTabBar(_ controller: BonsplitController, didClosePane paneId: PaneID)"
                description="Called after a pane is closed."
              />
              <APIMethod
                name="didFocusPane"
                signature="func splitTabBar(_ controller: BonsplitController, didFocusPane pane: PaneID)"
                description="Called when focus changes to a different pane."
              />
            </APISection>

            {/* BonsplitConfiguration */}
            <APISection
              title="BonsplitConfiguration"
              id="bonsplit-configuration"
            >
              <p className="text-[14px] text-[#666] dark:text-[#999] mt-2 mb-6 leading-relaxed">
                Configure behavior and appearance. Pass to BonsplitController on
                initialization.
              </p>

              <div className="bg-[#f8f9fa] dark:bg-[#111] rounded-md py-2 px-4">
                <Parameter
                  name="allowSplits"
                  type="Bool"
                  description="Enable split buttons and drag-to-split"
                  defaultValue="true"
                />
                <Parameter
                  name="allowCloseTabs"
                  type="Bool"
                  description="Show close buttons on tabs"
                  defaultValue="true"
                />
                <Parameter
                  name="allowCloseLastPane"
                  type="Bool"
                  description="Allow closing the last remaining pane"
                  defaultValue="false"
                />
                <Parameter
                  name="allowTabReordering"
                  type="Bool"
                  description="Enable drag-to-reorder tabs within a pane"
                  defaultValue="true"
                />
                <Parameter
                  name="allowCrossPaneTabMove"
                  type="Bool"
                  description="Enable moving tabs between panes via drag"
                  defaultValue="true"
                />
                <Parameter
                  name="autoCloseEmptyPanes"
                  type="Bool"
                  description="Automatically close panes when their last tab is closed"
                  defaultValue="true"
                />
                <Parameter
                  name="contentViewLifecycle"
                  type="ContentViewLifecycle"
                  description="How tab content views are managed when switching tabs"
                  defaultValue=".recreateOnSwitch"
                />
              </div>

              <div className="mt-6">
                <div className="text-[11px] font-medium text-[#888] uppercase tracking-wider mb-2">
                  Example
                </div>
                <CodeBlock>{`let config = BonsplitConfiguration(
    allowSplits: true,
    allowCloseTabs: true,
    allowCloseLastPane: false,
    autoCloseEmptyPanes: true,
    contentViewLifecycle: .keepAllAlive
)

let controller = BonsplitController(configuration: config)`}</CodeBlock>
              </div>

              <CategoryHeader>Content View Lifecycle</CategoryHeader>

              <p className="text-[14px] text-[#666] dark:text-[#999] mt-2 mb-4 leading-relaxed">
                Controls how tab content views are managed when switching
                between tabs.
              </p>

              <div className="overflow-x-auto bg-[#f8f9fa] dark:bg-[#111] rounded-md">
                <table className="w-full text-[13px]">
                  <thead>
                    <tr>
                      <th className="text-left py-2.5 px-4 font-medium text-[#666] dark:text-[#999]">
                        Mode
                      </th>
                      <th className="text-left py-2.5 px-4 font-medium text-[#666] dark:text-[#999]">
                        Memory
                      </th>
                      <th className="text-left py-2.5 px-4 font-medium text-[#666] dark:text-[#999]">
                        State
                      </th>
                      <th className="text-left py-2.5 px-4 font-medium text-[#666] dark:text-[#999]">
                        Use Case
                      </th>
                    </tr>
                  </thead>
                  <tbody className="text-[#666] dark:text-[#999]">
                    <tr>
                      <td className="py-2.5 px-4">
                        <code className="text-[#e06c75]">
                          .recreateOnSwitch
                        </code>
                      </td>
                      <td className="py-2.5 px-4">Low</td>
                      <td className="py-2.5 px-4">None</td>
                      <td className="py-2.5 px-4">Simple content</td>
                    </tr>
                    <tr>
                      <td className="py-2.5 px-4">
                        <code className="text-[#e06c75]">.keepAllAlive</code>
                      </td>
                      <td className="py-2.5 px-4">Higher</td>
                      <td className="py-2.5 px-4">Full</td>
                      <td className="py-2.5 px-4">Complex views, forms</td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <CategoryHeader>Appearance</CategoryHeader>

              <div className="bg-[#f8f9fa] dark:bg-[#111] rounded-md py-2 px-4">
                <Parameter
                  name="tabBarHeight"
                  type="CGFloat"
                  description="Height of the tab bar"
                  defaultValue="33"
                />
                <Parameter
                  name="tabMinWidth"
                  type="CGFloat"
                  description="Minimum width of a tab"
                  defaultValue="140"
                />
                <Parameter
                  name="tabMaxWidth"
                  type="CGFloat"
                  description="Maximum width of a tab"
                  defaultValue="220"
                />
                <Parameter
                  name="tabSpacing"
                  type="CGFloat"
                  description="Spacing between tabs"
                  defaultValue="0"
                />
                <Parameter
                  name="minimumPaneWidth"
                  type="CGFloat"
                  description="Minimum width of a pane"
                  defaultValue="100"
                />
                <Parameter
                  name="minimumPaneHeight"
                  type="CGFloat"
                  description="Minimum height of a pane"
                  defaultValue="100"
                />
                <Parameter
                  name="showSplitButtons"
                  type="Bool"
                  description="Show split buttons in the tab bar"
                  defaultValue="true"
                />
                <Parameter
                  name="animationDuration"
                  type="Double"
                  description="Duration of animations in seconds"
                  defaultValue="0.15"
                />
                <Parameter
                  name="enableAnimations"
                  type="Bool"
                  description="Enable or disable all animations"
                  defaultValue="true"
                />
              </div>

              <CategoryHeader>Presets</CategoryHeader>

              <div className="bg-[#f8f9fa] dark:bg-[#111] rounded-md py-2 px-4">
                <Parameter
                  name=".default"
                  type="BonsplitConfiguration"
                  description="Default configuration with all features enabled"
                />
                <Parameter
                  name=".singlePane"
                  type="BonsplitConfiguration"
                  description="Single pane mode with splits disabled"
                />
                <Parameter
                  name=".readOnly"
                  type="BonsplitConfiguration"
                  description="Read-only mode with all modifications disabled"
                />
              </div>
            </APISection>
          </div>
        </section>
      </div>

      {/* Side nav - 1 column */}
      <nav className="hidden lg:block lg:col-span-1">
        <div className="sticky top-8 font-mono text-[13px]">
          <ul>
            {sections.map(({ id, label }, index) => {
              const isActive = activeSection === id;
              const isLast = index === sections.length - 1;
              const prefix = isLast ? "└── " : "├── ";
              return (
                <li key={id} className="flex">
                  <span className="text-[#ccc] dark:text-[#444] select-none whitespace-pre">
                    {prefix}
                  </span>
                  <a
                    href={`#${id}`}
                    className={`transition-colors ${
                      isActive
                        ? "text-[#333] dark:text-[#eee]"
                        : "text-[#999] dark:text-[#666] hover:text-[#333] dark:hover:text-[#eee]"
                    }`}
                  >
                    {label}
                  </a>
                </li>
              );
            })}
          </ul>
        </div>
      </nav>
    </div>
  );
}
