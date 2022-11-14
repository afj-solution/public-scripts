const { test } = require("@playwright/test");
const { BASE_URL, LOGIN_PATH, CATEGORIES_PATH, PRODUCTS_PATH } = require("./constants");
const { getRandom, getRandomFloat } = require("./support");
const fs = require("fs");
const path = require("path");

const PRODUCT_COUNT = process.env.PRODUCT_COUNT 
    ? process.env.PRODUCT_COUNT 
    : 10;
const APP_USERNAME = process.env.APP_USERNAME;
const APP_PASSWORD = process.env.APP_PASSWORD;
const IMAGE_NAME = "index.jpg";
const RESOURCES_PATH = "buy-it-api/resources/";

test(`Generate products ${PRODUCT_COUNT} in the dev server`, async ({ request }) => {
    let token;
    let categories;
    const productName = "Citroen C4";

    await test.step("Login as admin to the", async () => {
        const response = await request.post(`${BASE_URL}${LOGIN_PATH}`, {
            data: {
                "username": APP_USERNAME,
                "password": APP_PASSWORD
            }
        })
        token = (await response.json()).token;
    });

    await test.step("Get categories of the product", async () => {
        const response = await request.get(`${BASE_URL}${CATEGORIES_PATH}`, {
            headers: {
                Authorization: `Bearer ${token}`
            }
        });
        categories = (await response.json()).content;
    });

    await test.step("Create product", async () => {
        const carCategory = categories.find(c => c.name === "Cars");
        const payload = {
            "categoryId": carCategory.id,
            "currency": "USD",
            "description": "Citroen cars can be used for the Taxi",
            "name": productName,
            "price": getRandomFloat(20000.00, 30000.00, 2),
            "quantity": getRandom(2, 10),
            "subCategoryId": carCategory.subCategory.id
          }
        await request.post(`${BASE_URL}${PRODUCTS_PATH}`, {
            headers: {
                Authorization: `Bearer ${token}`
            },
            data: payload
        });
    });

    await test.step("Upload image product", async () => {
        const file = path.resolve(RESOURCES_PATH, IMAGE_NAME);
        const image = fs.readFileSync(file);
        const productsResponse = await request.get(`${BASE_URL}${PRODUCTS_PATH}`, {
            headers: {
                "Authorization": `Bearer ${token}`
            },
        });
        const id = (await productsResponse.json()).content.find(product => 
            product.image === undefined && product.name === productName).id;
        await request.put(`${BASE_URL}${PRODUCTS_PATH}/${id}/image`, {
            headers: {
              Accept: "*/*",
              ContentType: "multipart/form-data",
              Authorization: `Bearer ${token}`
            },
            multipart: {
              file: {
                name: "index.jpg",
                mimeType: "image/jpg",
                buffer: image,
              },
            },
          });
    });
})