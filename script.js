const foodList = document.getElementById('food-list');
const totalCalories = document.getElementById('total-calories');
let caloriesTotal = 0;

document.getElementById('add-food').addEventListener('click', () => {
    const foodName = document.getElementById('food-name').value;
    const calories = parseInt(document.getElementById('calories').value);

    if (foodName && calories) {
        const li = document.createElement('li');
        li.innerHTML = `${foodName} - ${calories} calories <button>Remove</button>`;
        foodList.appendChild(li);

        caloriesTotal += calories;
        totalCalories.textContent = caloriesTotal;

        li.querySelector('button').addEventListener('click', () => {
            caloriesTotal -= calories;
            totalCalories.textContent = caloriesTotal;
            li.remove();
        });

        document.getElementById('food-name').value = '';
        document.getElementById('calories').value = '';
    }
});
