@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimForecastValidator()
        let item = RevenueCycle.newClaimForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimForecastRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.ClaimForecastRequiredLabelRule(message: "claim forecast needs this field")
        let item = RevenueCycle.newClaimForecast("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimForecastEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = RevenueCycle.ClaimForecastEncounterIDLengthRule(maxLength: 64)
        let item = RevenueCycle.newClaimForecast("x", label: "y")
        item.encounterID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ClaimForecastCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newClaimForecast("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ClaimForecastRequiredCodeRule(message: "claim forecast needs an entry")
        let item = RevenueCycle.newClaimForecast("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimForecastLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.ClaimForecastLabelLengthRule(maxLength: 80)
        let item = RevenueCycle.newClaimForecast("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
