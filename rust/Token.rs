use wasm_bindgen::prelude::*;
use std::collections::HashMap;

#[wasm_bindgen]
pub struct Token {
    supply: u64,
    balances: HashMap<String, u64>,
    compute_contributions: HashMap<String, u64>,
}

#[wasm_bindgen]
impl Token {
    #[wasm_bindgen(constructor)]
    pub fn new(supply: u64, creator: &str) -> Token {
        Token {
            supply: 0,
            balances: HashMap::new(),
            compute_contributions: HashMap::new(),
        }
    }

    pub fn balance(&self, user: &str) -> u64 {
        *self.balances.get(user).unwrap_or(&0)
}

pub fn balance_of(&self, user: &str) -> u64 {
    *self.balances.get(user).unwrap_or(&0)
}

pub fn transfer(&mut self, from: &str, to: &str, amount: u64) -> bool {
    let sender_balance = self.balance_of(from);

    if sender_balance < amount {
        return false;
    }

    let receiver_balance = self.balance_of(to);

    self.balances.insert(String::from(from), sender_balance - amount);
    self.balances.insert(String::from(to), receiver_balance + amount);
    
    true
}

pub fn add_compute_contribution(&mut self, user: &str, contribution: u64) {
    let compute_contributions = self.compute_contributions.entry(String::from(user)).or_insert(0);
    *compute_contributions += contribution;
    self.reward_user(user, contribution);
}

fn reward_user(&mut self, user: &str, contribution: u64) {
    // Define the reward logic based on the contribution (e.g., proportional to the contribution amount)
    let reward_amount = contribution / 10; // Example: reward 1 token per 10 units of compute contribution
    // Transfer the reward tokens from the creator to the user
    self.transfer("creator",user, reward_amount);
    }
}
