# Contributing to TOV.jl

We welcome contributions! Whether you're fixing a bug, improving documentation, or proposing a new feature, your help is appreciated.

## How to Contribute

1. **Fork the repository** on GitHub.
2. **Clone your fork** locally:

   ```bash
   git clone https://github.com/YOUR_USERNAME/TOV.jl.git
   ```

3. **Create a branch** for your changes:

   ```bash
   git checkout -b my-new-feature
   ```

4. **Make your changes**. Ensure you follow the Julia Style Guide.
5. **Run tests** to ensure no regressions:

   ```julia
   julia --project -e 'using Pkg; Pkg.test()'
   ```

6. **Commit and Push**:

   ```bash
   git commit -m "Add amazing new feature"
   git push origin my-new-feature
   ```

7. **Open a Pull Request** on the main repository.

## Standards

- **Code Style**: Follow the [Blue Style](https://github.com/invenia/BlueStyle) or standard Julia guidelines.
- **Documentation**: Add docstrings to new functions and update the `docs/` folder if necessary.
- **Tests**: Add units tests for any new physics or logic.

## Reporting Issues

Please open an issue on GitHub if you encounter bugs or have feature requests. Provide a minimal working example (MWE) if possible.
