window.addEventListener('DOMContentLoaded', event => {

    // Activate Bootstrap scrollspy on the main nav element
    const sideNav = document.body.querySelector('#sideNav');
    if (typeof bootstrap !== 'undefined' && sideNav) {
        new bootstrap.ScrollSpy(document.body, {
            target: '#sideNav',
            rootMargin: '0px 0px -40%',
        });
    }

    // Collapse responsive navbar when toggler is visible
    const navbarToggler = document.body.querySelector('.navbar-toggler');
    const responsiveNavItems = document.querySelectorAll('#navbarResponsive .nav-link');
    responsiveNavItems.forEach(responsiveNavItem => {
        responsiveNavItem.addEventListener('click', () => {
            if (window.getComputedStyle(navbarToggler).display !== 'none') {
                navbarToggler.click();
            }
        });
    });

    // Function to fetch visitor count from API endpoint

    const counter = document.querySelector(".counter-number");
    async function updateCounter() {
        let response = await fetch(
            "https://8t23sxpg57.execute-api.us-east-1.amazonaws.com"
        );
        let data = await response.json();
        counter.innerHTML = `👀 Views: ${data}`;
    }
    updateCounter();

});