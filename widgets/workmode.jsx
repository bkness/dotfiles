 ////---------------------\\\\
//// # Workmode widget #   \\\\
///---------∆∆∆------------||||
///---------∆∆∆------------||||
//_________________________||||

const skin = Math.floor(Date.now() / (4 * 60 * 60 * 1000)) % 3;

const stripeAnim = {
  type: "swing",
  duration: 3,
  direction: "vertical",
  distance: 60,
};

const triggerWorkmode = () => {
    scheme.open("shortcuts://run-shortcut?name=Workmode");
};

if (skin === 0) {
  $render(
    <zstack frame="max">
      <rect frame="max" color="#000000" />
      <rect frame="max" color="#00ff0008" />
      <vstack frame="max" spacing="0">
        <hstack frame="max,22" padding="6,4" spacing="4" background="#00ff41">
          <text font="caption2" color="#000000">devforge — boot.sh</text>
          <rect frame="max,1" color="#00000000" />
          <rect frame="6,6" color="#00000099" corner="3" />
          <rect frame="6,6" color="#00000099" corner="3" />
          <rect frame="6,6" color="#00000099" corner="3" />
        </hstack>
        <vstack frame="max" padding="10,8" spacing="3" alignment="leading">
          <text font="caption2" color="#004d00">$ loading workflow manifest...</text>
          <text font="caption2" color="#88ff88">✓ tasks queued</text>
          <text font="caption2" color="#004d00">$ awaiting ignition signal_</text>
        </vstack>
        <hstack frame="max" padding="8">
          <rect frame="max,1" color="#00000000" />
          <button onClick="triggerWorkmode">
            <text font="caption2" color="#00ff41">[ EXECUTE ]</text>
          </button>
        </hstack>
      </vstack>
    </zstack>
  );
} else if (skin === 1) {
  $render(
    <zstack frame="max">
      <rect frame="max" color="#0d1117" />

      {/* Top-left corner bracket */}
      <vstack frame="max" alignment="leading" padding="10">
        <hstack spacing="0">
          <vstack spacing="0">
            <rect frame="16,2" color="#58a6ff99" />
            <rect frame="2,14" color="#58a6ff99" />
          </vstack>
        </hstack>
      </vstack>

      {/* Top-right corner bracket */}
      <vstack frame="max" alignment="trailing" padding="10">
        <hstack spacing="0">
          <vstack spacing="0" alignment="trailing">
            <rect frame="16,2" color="#58a6ff99" />
            <hstack><rect frame="max,1" color="#00000000" /><rect frame="2,14" color="#58a6ff99" /></hstack>
          </vstack>
        </hstack>
      </vstack>

      {/* Bottom-left corner bracket */}
      <vstack frame="max" alignment="leading" padding="10">
        <rect frame="max,1" color="#00000000" />
        <hstack spacing="0">
          <vstack spacing="0">
            <rect frame="2,14" color="#58a6ff99" />
            <rect frame="16,2" color="#58a6ff99" />
          </vstack>
        </hstack>
      </vstack>

      {/* Bottom-right corner bracket */}
      <vstack frame="max" alignment="trailing" padding="10">
        <rect frame="max,1" color="#00000000" />
        <hstack spacing="0">
          <vstack spacing="0" alignment="trailing">
            <hstack><rect frame="max,1" color="#00000000" /><rect frame="2,14" color="#58a6ff99" /></hstack>
            <rect frame="16,2" color="#58a6ff99" />
          </vstack>
        </hstack>
      </vstack>

      {/* Content */}
      <vstack frame="max" padding="14,12" spacing="8">
        <hstack frame="max" spacing="6">
          <text font="caption2" color="#3fb950">●</text>
          <text font="caption2" color="#58a6ff">SYSTEM READY</text>
          <rect frame="max,1" color="#00000000" />
        </hstack>
        <text font="headline" color="#e6edf3">BOOT SHELL</text>
        <text font="caption2" color="#6e7681">WORKFLOW TRIGGER // v2.4</text>
        <hstack frame="max" spacing="20">
          <vstack spacing="2">
            <text font="title3" color="#58a6ff">12</text>
            <text font="caption2" color="#444d56">TASKS</text>
          </vstack>
          <vstack spacing="2">
            <text font="title3" color="#58a6ff">0ms</text>
            <text font="caption2" color="#444d56">LATENCY</text>
          </vstack>
          <vstack spacing="2">
            <text font="title3" color="#58a6ff">100%</text>
            <text font="caption2" color="#444d56">READY</text>
          </vstack>
        </hstack>
        <button onClick="triggerWorkmode" background="#1f6feb" corner="8">
          <text font="caption" color="#ffffff">▶  LAUNCH WORKFLOW</text>
        </button>
      </vstack>
    </zstack>
  );
} else {
  $render(
    <zstack frame="max">
      <rect frame="max" color="#05000f" />
      <vstack frame="max" spacing="0">
        <rect frame="max,2" color="#ff0090" />
        <rect frame="max,max" color="#00000000" />
        <rect frame="max,2" color="#ff0090" />
      </vstack>
      <rect frame="max,2" color="#ff009099" animation={$animation(stripeAnim)} />
      <vstack frame="max" padding="16,12" spacing="6">
        <text font="caption2" color="#ff0090">// DEVFORGE SYSTEM</text>
        <zstack>
          <text font="title2" color="#ff009055" offset="-2,0">BOOT_SHELL.EXE</text>
          <text font="title2" color="#00ffff55" offset="2,0">BOOT_SHELL.EXE</text>
          <text font="title2" color="#ffffff">BOOT_SHELL.EXE</text>
        </zstack>
        <hstack frame="max">
          <vstack spacing="2" alignment="leading">
            <hstack spacing="4">
              <text font="caption2" color="#ff009066">TASKS</text>
              <text font="caption2" color="#ff0090">12</text>
            </hstack>
            <hstack spacing="4">
              <text font="caption2" color="#ff009066">STATUS</text>
              <text font="caption2" color="#ff0090">ARMED</text>
            </hstack>
          </vstack>
          <spacer />
          <button onClick="triggerWorkmode">
            <text font="caption" color="#ff0090">FIRE</text>
          </button>
        </hstack>
      </vstack>
    </zstack>
  );
}
