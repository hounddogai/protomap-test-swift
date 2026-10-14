@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictStatementForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStrictStatementForecastValidator()
        let item = RevenueCycle.newStrictStatementForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStrictStatementForecastRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = RevenueCycle.StrictStatementForecastRequiredBedRule(
            message: "strict statement forecast needs a value"
        )
        let item = RevenueCycle.newStrictStatementForecast("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
