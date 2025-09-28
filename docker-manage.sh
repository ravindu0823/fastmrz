#!/bin/bash

# FastMRZ Docker Management Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  dev       Start development environment with hot reload"
    echo "  prod      Start production environment"
    echo "  build     Build Docker images"
    echo "  stop      Stop all containers"
    echo "  clean     Clean up containers and images"
    echo "  logs      Show logs"
    echo "  shell     Access container shell"
    echo "  test      Test API endpoints"
    echo "  help      Show this help message"
}

# Function to start development environment
start_dev() {
    print_status "Starting development environment..."
    docker-compose -f docker-compose.dev.yml up --build -d
    print_status "Development environment started!"
    print_status "API available at: http://localhost:8000"
    print_status "API docs at: http://localhost:8000/docs"
}

# Function to start production environment
start_prod() {
    print_status "Starting production environment..."
    docker-compose --profile production up --build -d
    print_status "Production environment started!"
    print_status "API available at: http://localhost:8000"
    print_status "Nginx proxy at: http://localhost:80"
}

# Function to build images
build_images() {
    print_status "Building Docker images..."
    docker-compose build
    print_status "Images built successfully!"
}

# Function to stop containers
stop_containers() {
    print_status "Stopping containers..."
    docker-compose down
    docker-compose -f docker-compose.dev.yml down
    print_status "Containers stopped!"
}

# Function to clean up
clean_up() {
    print_warning "This will remove all containers, images, and volumes. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_status "Cleaning up..."
        docker-compose down -v --rmi all
        docker-compose -f docker-compose.dev.yml down -v --rmi all
        docker system prune -f
        print_status "Cleanup completed!"
    else
        print_status "Cleanup cancelled."
    fi
}

# Function to show logs
show_logs() {
    print_status "Showing logs..."
    docker-compose logs -f
}

# Function to access shell
access_shell() {
    print_status "Accessing container shell..."
    docker-compose exec fastmrz-api bash
}

# Function to test API
test_api() {
    print_status "Testing API endpoints..."
    
    # Test health endpoint
    if curl -f http://localhost:8000/healthz > /dev/null 2>&1; then
        print_status "✓ Health check passed"
    else
        print_error "✗ Health check failed"
        return 1
    fi
    
    # Test readiness endpoint
    if curl -f http://localhost:8000/readyz > /dev/null 2>&1; then
        print_status "✓ Readiness check passed"
    else
        print_error "✗ Readiness check failed"
        return 1
    fi
    
    print_status "✓ All tests passed!"
}

# Main script logic
case "${1:-help}" in
    dev)
        start_dev
        ;;
    prod)
        start_prod
        ;;
    build)
        build_images
        ;;
    stop)
        stop_containers
        ;;
    clean)
        clean_up
        ;;
    logs)
        show_logs
        ;;
    shell)
        access_shell
        ;;
    test)
        test_api
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
