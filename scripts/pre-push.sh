#!/bin/bash

# Pre-push validation script
# Run this before pushing to ensure CI will pass

echo "🔍 Running pre-push checks..."
echo ""

# Check formatting
echo "📝 Checking code formatting..."
dart format --output=none --set-exit-if-changed .
if [ $? -ne 0 ]; then
    echo "❌ Code formatting issues found. Run: dart format ."
    exit 1
fi
echo "✅ Code formatting OK"
echo ""

# Analyze code
echo "🔬 Analyzing code..."
flutter analyze
if [ $? -ne 0 ]; then
    echo "❌ Analysis found issues"
    exit 1
fi
echo "✅ Analysis passed"
echo ""

# Run tests
echo "🧪 Running tests..."
flutter test
if [ $? -ne 0 ]; then
    echo "❌ Tests failed"
    exit 1
fi
echo "✅ All tests passed"
echo ""

# Generate coverage
echo "📊 Generating test coverage..."
flutter test --coverage > /dev/null 2>&1
if [ -f coverage/lcov.info ]; then
    echo "✅ Coverage report generated"
else
    echo "⚠️  Warning: Coverage report not generated"
fi
echo ""

echo "✨ All checks passed! Safe to push."
