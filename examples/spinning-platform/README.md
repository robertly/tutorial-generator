# Spinning platform

A classic game-juice effect: a platform that spins on its vertical axis
forever. Shows how to drive continuous behavior from a `Script` using
`RunService.Heartbeat` — the per-frame server tick.

## What it shows

- `RunService.Heartbeat:Connect` for per-frame logic.
- Rotating an anchored Part via CFrame without physics.
- `deltaTime` (the callback's single argument) as the right "time scale"
  for smooth, frame-rate-independent motion.

## Components

- **Workspace.Platform** — an anchored, flat Part that acts as the
  platform surface.
- **Workspace.Platform.Spinner** — a `Script` under it that rotates the
  platform on each Heartbeat.

## Flow

1. Create the platform Part in Workspace.
2. Add the Spinner Script that rotates it with `CFrame * CFrame.Angles`.
3. Suggest extending with a Y bob via Assistant.
4. Playtest: press Play, watch the platform spin in place.

## Assets

None.
