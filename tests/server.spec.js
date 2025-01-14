const fs = require("fs");
const request = require("supertest");
const app = require("../server");

const e2eOutput = { food: [], textile: [] };

describe("Web", () => {
  it("should render the homepage", async () => {
    const response = await request(app).get("/");

    expectStatus(response, 200, "text/html");
    expect(response.text).toContain("<title>Ecobalyse</title>");
  });
});

describe("API", () => {
  describe("Not found", () => {
    it("should render a 404 response", async () => {
      const response = await request(app).get("/xxx");

      expectStatus(response, 404, "text/html");
    });
  });

  describe("Common", () => {
    describe("/api", () => {
      it("should render the OpenAPI documentation", async () => {
        const response = await request(app).get("/api");

        expectStatus(response, 200);
        expect(response.body.openapi).toEqual("3.0.1");
        expect(response.body.info.title).toEqual("API Ecobalyse");
      });
    });
  });

  describe("Textile", () => {
    const successQuery =
      // Successful query params.
      // Note: it's important to pass query string parameters as actual strings here,
      // so we can test for actual qs parsing from the server.
      [
        "mass=0.17",
        "product=tshirt",
        "materials[]=coton;0.5",
        "materials[]=acrylique;0.5",
        "countryFabric=CN",
        "countryDyeing=CN",
        "countryMaking=CN",
      ];

    describe("/textile/countries", () => {
      it("should render with textile countries list", async () => {
        await expectListResponseContains("/api/textile/countries", { code: "FR", name: "France" });
      });
    });

    describe("/materials", () => {
      it("should render with materials list", async () => {
        await expectListResponseContains("/api/textile/materials", {
          id: "coton",
          name: "Fil de coton conventionnel, inventaire partiellement agrégé",
        });
      });
    });

    describe("/products", () => {
      it("should render with products list", async () => {
        await expectListResponseContains("/api/textile/products", {
          id: "tshirt",
          name: "T-shirt",
        });
      });
    });

    describe("/simulator", () => {
      it("should accept a valid query", async () => {
        const response = await makeRequest("/api/textile/simulator", successQuery);

        expectStatus(response, 200);
        expect(response.body.impacts.cch).toBeGreaterThan(0);
      });

      it("should validate the mass param", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["mass=-1"]),
          "mass",
          /supérieure ou égale à zéro/,
        );
      });

      it("should validate the materials param", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["materials[]=xxx;1"]),
          "materials",
          /Matière non trouvée id=xxx/,
        );
      });

      it("should validate the product param", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["product=xxx"]),
          "product",
          /Produit non trouvé id=xxx/,
        );
      });

      it("should validate the country params are present", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["countryFabric=FR,countryDyeing=FR"]),
          "countryMaking",
          /Code pays manquant/,
        );
      });

      it("should validate the countryFabric param (invalid code)", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["countryFabric=XX"]),
          "countryFabric",
          /Code pays invalide: XX/,
        );
      });

      it("should validate the countryDyeing param (invalid code)", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["countryDyeing=XX"]),
          "countryDyeing",
          /Code pays invalide: XX/,
        );
      });

      it("should validate the countryMaking param (invalid code)", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["countryMaking=XX"]),
          "countryMaking",
          /Code pays invalide: XX/,
        );
      });

      it("should validate the disabledSteps param", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["disabledSteps=xxx"]),
          "disabledSteps",
          /Code étape inconnu: xxx/i,
        );
      });

      it("should validate the dyeingMedium param", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["dyeingMedium=xxx"]),
          "dyeingMedium",
          /support de teinture inconnu: xxx/i,
        );
      });

      it("should perform a simulation featuring 14 impacts for textile", async () => {
        const response = await makeRequest("/api/textile/simulator/", successQuery);

        expectStatus(response, 200);
        expect(Object.keys(response.body.impacts)).toHaveLength(14);
      });

      it("should validate the airTransportRatio param", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["airTransportRatio=2"]),
          "airTransportRatio",
          /doit être compris entre/,
        );
      });

      it("should validate the makingWaste param", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["makingWaste=0.9"]),
          "makingWaste",
          /doit être compris entre/,
        );
      });

      it("should validate the picking param", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["picking=10"]),
          "picking",
          /doit être compris entre/,
        );
      });

      it("should validate the surfaceMass param", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["surfaceMass=10"]),
          "surfaceMass",
          /doit être compris entre/,
        );
      });

      it("should validate the disabledFading param", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["disabledFading=untrue"]),
          "disabledFading",
          /ne peut être que true ou false/,
        );
      });

      it("should validate the printing param", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["printing=bonk"]),
          "printing",
          /Format de type et surface d'impression invalide: bonk/,
        );
      });

      it("should validate the ennoblingHeatSource param", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/textile/simulator", ["ennoblingHeatSource=bonk"]),
          "ennoblingHeatSource",
          /Source de production de vapeur inconnue: bonk/,
        );
      });
    });

    describe("/simulator/fwe", () => {
      it("should accept a valid query", async () => {
        const response = await makeRequest("/api/textile/simulator/fwe", successQuery);

        expectStatus(response, 200);
        expect(response.body.impacts.fwe).toBeGreaterThan(0);
      });
    });

    describe("/simulator/detailed", () => {
      it("should accept a valid query", async () => {
        const response = await makeRequest("/api/textile/simulator/detailed", successQuery);

        expectStatus(response, 200);
        expect(response.body.lifeCycle).toHaveLength(8);
      });
    });

    describe("End to end textile simulations", () => {
      const e2eTextile = JSON.parse(fs.readFileSync(`${__dirname}/e2e-textile.json`).toString());

      for (const { name, query, impacts } of e2eTextile) {
        it(name, async () => {
          const response = await makeRequest("/api/textile/simulator", query);
          expectStatus(response, 200);
          e2eOutput.textile.push({
            name,
            query,
            impacts: response.body.impacts,
          });
          expect(response.body.impacts).toEqual(impacts);
        });
      }
    });
  });

  describe("Food", () => {
    describe("/food/countries", () => {
      it("should render with food countries list", async () => {
        await expectListResponseContains("/api/food/countries", { code: "FR", name: "France" });
      });
    });

    describe("/food/ingredients", () => {
      it("should render with ingredients list", async () => {
        await expectListResponseContains("/api/food/ingredients", {
          id: "milk",
          name: "Lait",
          defaultOrigin: "Europe et Maghreb"
        });
      });
    });

    describe("/food/transforms", () => {
      it("should render with transforms list", async () => {
        await expectListResponseContains("/api/food/transforms", {
          code: "aded2490573207ec7ad5a3813978f6a4",
          name: "Cuisson",
        });
      });
    });

    describe("/food/recipe", () => {
      it("should compute 19 impacts for food", async () => {
        const response = await makeRequest("/api/food/recipe", [
          "ingredients[]=carrot;268",
          "transform=aded2490573207ec7ad5a3813978f6a4;1050",
        ]);

        expectStatus(response, 200);
        expect(Object.keys(response.body.results.total)).toHaveLength(19);
      });

      it("should validate the ingredient list length", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/food/recipe", []),
          "ingredients",
          /liste des ingrédients est vide/,
        );
      });

      it("should validate an ingredient id", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/food/recipe", ["ingredients[]=invalid;268"]),
          "ingredients",
          /Ingrédient introuvable par id : invalid/,
        );
      });

      it("should validate an ingredient mass", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/food/recipe", ["ingredients[]=carrot;-1"]),
          "ingredients",
          /masse doit être supérieure ou égale à zéro/,
        );
      });
      
      it("should validate an ingredient variant", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/food/recipe", ["ingredients[]=carrot;123;BadVariant"]),
          "ingredients",
          /Format de variant invalide : BadVariant/,
        );
      });

      it("should validate an ingredient country code", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/food/recipe", ["ingredients[]=carrot;123;default;BadCountryCode"]),
          "ingredients",
          /Code pays invalide: BadCountryCode/,
        );
      });

      it("should validate an ingredient transport by plane value", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/food/recipe", ["ingredients[]=mango;123;default;BR;badValue"]),
          "ingredients",
          /La valeur ne peut être que parmis les choix suivants: 'default', 'byPlane', 'noPlane'./,
        );
      });

      it("should validate an ingredient transport by plane", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/food/recipe", ["ingredients[]=carrot;123;default;BR;byPlane"]),
          "ingredients",
          /Impossible de spécifier un acheminement par avion pour cet ingrédient, son origine par défaut ne le permet pas./,
        );
      });

      it("should validate transform code", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/food/recipe", ["transform=invalid;268"]),
          "transform",
          /Procédé introuvable par code : invalid/,
        );
      });

      it("should validate a transform mass", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/food/recipe", ["transform=aded2490573207ec7ad5a3813978f6a4;-1"]),
          "transform",
          /masse doit être supérieure ou égale à zéro/,
        );
      });

      it("should validate a packaging code", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/food/recipe", ["packaging[]=invalid;268"]),
          "packaging",
          /Procédé introuvable par code : invalid/,
        );
      });

      it("should validate a packaging mass", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/food/recipe", [
            "packaging[]=23b2754e5943bc77916f8f871edc53b6;-1",
          ]),
          "packaging",
          /masse doit être supérieure ou égale à zéro/,
        );
      });

      it("should validate a category id", async () => {
        expectFieldErrorMessage(
          await makeRequest("/api/food/recipe", ["category=invalid"]),
          "category",
          /Catégorie inconnue: invalid/,
        );
      });
    });

    describe("End to end food simulations", () => {
      const e2eFood = JSON.parse(fs.readFileSync(`${__dirname}/e2e-food.json`).toString());

      for (const { name, query, impacts, scoring } of e2eFood) {
        it(name, async () => {
          const response = await makeRequest("/api/food/recipe", query);
          expectStatus(response, 200);
          e2eOutput.food.push({
            name,
            query,
            impacts: response.body.results.total,
            scoring: response.body.results.scoring,
          });
          expect(response.body.results.total).toEqual(impacts);
          expect(response.body.results.scoring).toEqual(scoring);
        });
      }
    });
  });
});

afterAll(() => {
  // Write the output results to new files, in case we want to update the old ones
  // with their contents.
  function writeE2eResult(key) {
    const target = `${__dirname}/e2e-${key}-output.json`;
    fs.writeFileSync(target, JSON.stringify(e2eOutput[key], null, 2) + "\n");
    console.info(`E2e ${key} tests output written to ${target}.`);
  }

  writeE2eResult("textile");
  writeE2eResult("food");
});

// Test helpers

async function makeRequest(path, query = []) {
  return await request(app).get(path).query(query.join("&"));
}

function expectFieldErrorMessage(response, field, message) {
  expectStatus(response, 400);
  expect("errors" in response.body).toEqual(true);
  expect(field in response.body.errors).toEqual(true);
  expect(response.body.errors[field]).toMatch(message);
}

async function expectListResponseContains(path, object) {
  const response = await request(app).get(path);

  expectStatus(response, 200);
  expect(response.body).toContainObject(object);
}

function expectStatus(response, code, type = "application/json") {
  expect(response.type).toBe(type);
  expect(response.statusCode).toBe(code);
}

// https://medium.com/@andrei.pfeiffer/jest-matching-objects-in-array-50fe2f4d6b98
expect.extend({
  toContainObject(received, argument) {
    if (this.equals(received, expect.arrayContaining([expect.objectContaining(argument)]))) {
      return {
        message: () =>
          `expected ${this.utils.printReceived(
            received,
          )} not to contain object ${this.utils.printExpected(argument)}`,
        pass: true,
      };
    }
    return {
      message: () =>
        `expected ${this.utils.printReceived(
          received,
        )} to contain object ${this.utils.printExpected(argument)}`,
      pass: false,
    };
  },
});
