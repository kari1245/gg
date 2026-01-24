
# Copilot Instructions for gg Codebase

## Overview
This project is a Roblox game using Luau with a **flat modular architecture**. Each feature has its own Service (server) and Controller (client) pair. The architecture prioritizes security, performance, clean code, and maintainability.

## Official Documentation
- **Roblox Engine API**: [Reference](https://create.roblox.com/docs/reference/engine)
- **ProfileStore**: [Documentation](https://madstudioroblox.github.io/ProfileStore/api/)

## Architecture & Key Directories
- **src/ReplicatedStorage/**: Shared code and packages accessible by both client and server. Includes:
  - **Common/**: Shared configuration (see GameConfig.luau).
  - **Packages/**: Third-party and utility modules (Promise, Signal, Trove, ProfileStore, etc.).
- **src/ServerScriptService/**: Server-side logic, especially services (e.g., PlanetService.luau).
  - Each feature has its own **Service** for server-side logic and data management.
- **src/StarterPlayerScripts/**: Client-side controllers organized by feature (e.g., PlanetStreamingController.luau).
  - Each feature has its own **Controller** for client-side logic.
  - GUIs are designed in Roblox Studio (not programmatic Fusion UIs).

## Developer Workflows
- **Build**: Run `argon build` in the project root to build the place file.
- **Sync/Serve**: Use `argon serve` and open Roblox Studio to sync changes during development.
- **No explicit test or lint commands found**; follow project conventions for manual testing in Roblox Studio.

## Native Development Workflow (VS Code + MCP)
- **All code/script development must be done natively in VS Code**: Write, edit, and manage all Luau scripts (.luau) in VS Code for full version control and code quality.
- **All instance/model/GUI/visual editing must be done via MCP server in Roblox Studio**: Use MCP tools to create, modify, and organize Parts, Models, GUIs, and set properties visually.
- **Never edit script source code through MCP**: Always use VS Code for any code changes to ensure clean Git history and avoid sync issues.
- **This is the only supported workflow**: Do not use other tools or plugins for code or instance management. Always keep code and visual/instance work separated as above.


## Development Tools & Workflow
- **VS Code (Native Editing)**: 
  - Write and edit all Luau script files (.luau)
  - Implement logic, functions, controllers, services
  - Use file search, grep, and semantic search for code navigation
  - Git integration for version control
  - All code changes should be made in VS Code for proper sync
- **MCP Server (Roblox Studio Integration)**:
  - Create and manipulate 3D models, parts, and instances
  - Design GUI elements visually (ScreenGuis, Frames, Buttons, etc.)
  - Set properties (Size, Position, Color, Anchored, Transparency, etc.)
  - Manage hierarchy and instance organization
  - Add tags and attributes to instances
  - Search for instances by name, class, or properties
  - **Do NOT edit script source code through MCP** - use VS Code instead
- **Workflow Philosophy**:
  - Code = VS Code (text editing, logic, version control)
  - Visual/Instances = Studio via MCP (models, GUIs, properties)
  - This separation ensures clean Git history and proper file management

## Project-Specific Conventions
- **Flat Modular Structure**: Each feature has its own Service (server) and Controller (client) in dedicated folders.
- **Feature Organization**: Each gameplay feature (Planet, ...) has:
  - **Service** in `src/ServerScriptService/Services/` - Server logic, validation, data management
  - **Controller** in `src/StarterPlayerScripts/Controllers/` - Client logic, UI binding, input handling
- **GUI Design**: UIs are created visually in Roblox Studio, not programmatically with Fusion
- **Data Persistence**: Use **ProfileStore** for all user data storage (not DataStore directly)
- **Packages**: Utility and third-party modules in `src/ReplicatedStorage/Packages/`
- **Shared Config**: Game-wide configuration in `src/ReplicatedStorage/Common/GameConfig.luau`

## Security Best Practices
- **Server Authority**: All game logic, validation, and data changes happen on the server
- **Input Validation**: Always validate client requests in Services before processing
- **Remote Security**: Never trust client data - verify permissions, ownership, and sanity checks
- **Anti-Exploit Patterns**:
  - Rate limiting on remote calls
  - Server-side cooldowns and checks
  - Sanity checks on all numerical values (amounts, prices, positions)
  - No client-side money/inventory manipulation
- **ProfileStore Usage**: Proper session locking, reconciliation, and error handling

## Performance Best Practices
- **Lazy Loading**: Load resources and data only when needed
- **Object Pooling**: Reuse instances instead of creating/destroying repeatedly
- **Event Optimization**: Clean up connections with Trove, avoid memory leaks
- **Efficient Loops**: Use `ipairs` for arrays, avoid unnecessary `pairs` iterations
- **Remote Batching**: Batch multiple remote calls when possible
- **Debouncing**: Debounce rapid user inputs to prevent spam

## Integration & Communication
- **RemoteFunction/RemoteEvent**: Use Roblox RemoteFunction and RemoteEvent for all client-server communication. Do NOT use Knit or Comm. Always validate and sanitize all remote calls on the server.
- **ProfileStore**: Used for persistent player data storage with session locking
- **Signal/Promise/Trove**: Common utility patterns for events, async operations, and resource cleanup

## Code Quality Standards
- **Clean Code Principles**:
  - Clear, descriptive variable and function names
  - Keep functions small and single-purpose
  - Comment complex logic, not obvious code
  - Consistent formatting and style
- **Error Handling**: Use pcall/xpcall for risky operations, log errors clearly
- **Type Safety**: Use type annotations where helpful for clarity
- **Documentation**: Document public APIs, complex algorithms, and non-obvious behavior

## Patterns & Examples
- **Controllers**: Client logic (e.g., `PlanetStreamingController.luau`) handles UI, input, and communicates with server via RemoteFunction/RemoteEvent
- **Services**: Server logic (e.g., `PlanetService.luau`) validates requests, manages data via ProfileStore, exposes APIs to clients via RemoteFunction/RemoteEvent
- **Data Management**: DataService handles ProfileStore loading/saving, other services access player data through it

## External Dependencies
- **Argon**: Used for build and sync workflows
- **ProfileStore**: Robust data persistence system
- **sleitnick packages**: Signal, Promise, Trove, Component, and other utilities

## Tips for AI Agents
- Ưu tiên đọc kỹ Roblox Engine API để hiểu rõ các class, property, method chuẩn
- Sử dụng RemoteFunction/RemoteEvent cho mọi giao tiếp client-server
- Đặt logic xác thực, kiểm tra dữ liệu ở phía server
- Thiết kế GUI trực quan trong Studio, không code UI bằng Fusion
- Ưu tiên hiệu năng, bảo mật, và code sạch
- **Tool Selection**:
  - Dùng VS Code file tools (read_file, replace_string_in_file, etc.) cho TẤT CẢ chỉnh sửa script
  - Dùng MCP tools (create_object, set_property, ...) CHỈ cho instance, model, GUI trong Studio
  - Không bao giờ sửa code script qua MCP - luôn dùng VS Code cho code

---
If any section is unclear or missing, please provide feedback for further refinement.
