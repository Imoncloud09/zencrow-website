document.addEventListener('DOMContentLoaded', () => {
    // Initialize Three.js scene
    const container = document.getElementById('3d-container');
    if (!container) return;

    // Scene setup
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0xf8fafc);

    const camera = new THREE.PerspectiveCamera(
        75,
        container.clientWidth / container.clientHeight,
        0.1,
        1000
    );

    const renderer = new THREE.WebGLRenderer({
        antialias: true,
        alpha: false
    });

    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(window.devicePixelRatio);
    container.appendChild(renderer.domElement);

    // Lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    scene.add(ambientLight);

    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(5, 5, 5);
    scene.add(directionalLight);

    // Create a tech-themed 3D model
    const createTechOrbit = () => {
        const group = new THREE.Group();

        // Central sphere (representing core technology)
        const geometry = new THREE.SphereGeometry(1, 32, 32);
        const material = new THREE.MeshPhongMaterial({
            color: 0x2563eb,
            shininess: 100
        });
        const sphere = new THREE.Mesh(geometry, material);
        group.add(sphere);

        // Orbiting cubes (representing services)
        for (let i = 0; i < 3; i++) {
            const cubeGeometry = new THREE.BoxGeometry(0.5, 0.5, 0.5);
            const cubeMaterial = new THREE.MeshPhongMaterial({
                color: i === 0 ? 0xf59e0b : (i === 1 ? 0x10b981 : 0x8b5cf6),
                shininess: 50
            });
            const cube = new THREE.Mesh(cubeGeometry, cubeMaterial);

            // Position cubes in orbit
            const angle = (i / 3) * Math.PI * 2;
            cube.position.x = Math.cos(angle) * 2;
            cube.position.z = Math.sin(angle) * 2;

            // Add animation properties
            cube.userData = {
                speed: 0.5 + Math.random() * 0.5,
                angle: angle,
                radius: 2 + Math.random() * 0.5
            };

            group.add(cube);
        }

        return group;
    };

    const techOrbit = createTechOrbit();
    scene.add(techOrbit);

    camera.position.z = 5;

    // Animation loop
    function animate() {
        requestAnimationFrame(animate);

        // Rotate the central sphere
        techOrbit.rotation.y += 0.005;

        // Animate orbiting cubes
        techOrbit.children.forEach(child => {
            if (child.userData.speed) {
                child.userData.angle += 0.01 * child.userData.speed;
                child.position.x = Math.cos(child.userData.angle) * child.userData.radius;
                child.position.z = Math.sin(child.userData.angle) * child.userData.radius;
                child.rotation.x += 0.01;
                child.rotation.y += 0.01;
            }
        });

        renderer.render(scene, camera);
    }

    // Handle window resize
    const handleResize = () => {
        camera.aspect = container.clientWidth / container.clientHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(container.clientWidth, container.clientHeight);
    };

    window.addEventListener('resize', handleResize);

    // Initial render
    handleResize();
    animate();
});