#!/usr/bin/env python3
"""
Simple wrapper for Task Master Node.js CLI
Allows Python integration with the Node.js task-master commands
"""
import subprocess
import sys
import shutil

def main():
    """Main entry point that forwards to task-master CLI"""
    # Check if task-master is available globally
    if shutil.which('task-master'):
        # Forward all arguments to the actual task-master CLI
        result = subprocess.run(['task-master'] + sys.argv[1:], 
                              capture_output=False, 
                              text=True)
        sys.exit(result.returncode)
    
    # Try npx as fallback
    elif shutil.which('npx'):
        result = subprocess.run(['npx', 'task-master-ai'] + sys.argv[1:], 
                              capture_output=False, 
                              text=True)
        sys.exit(result.returncode)
    
    else:
        print("❌ Task Master CLI not found. Install with:")
        print("   npm install -g task-master-ai")
        print("   # or ensure npx is available")
        sys.exit(1)

if __name__ == "__main__":
    main()