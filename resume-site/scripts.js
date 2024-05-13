const counter = document.querySelector(".counter-number");

// Function to update counter
async function updateCounter() {
    let response = await fetch(
        "https://p2znc5c5ien66ffypmaganbb2i0nbynn.lambda-url.us-east-1.on.aws/"
    );
    let data = await response.json();
    counter.innerHTML = `👀 Views: ${data}`;
}


// Update counter on page load
updateCounter();
