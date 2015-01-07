
describe("hello-protractor", function () {

  beforeEach( function() {

  });

    describe("index", function () {
        it("should display the correct title", function() {
            browser.get('/#');
            expect(browser.getTitle()).toBe('Performance Analysis Visualization App');
        });
    });
});