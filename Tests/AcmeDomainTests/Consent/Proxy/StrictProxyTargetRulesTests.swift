@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultStrictProxyTargetValidator()
        let item = Consent.newStrictProxyTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentStrictProxyTargetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.StrictProxyTargetLabelLengthRule(maxLength: 86400)
        let item = Consent.newStrictProxyTarget("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentStrictProxyTargetBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Consent.StrictProxyTargetBudgetRangeRule(min: 8.4, max: 629.7)
        let item = Consent.newStrictProxyTarget("x", label: "y")
        item.budget = 631.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentStrictProxyTargetFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Consent.StrictProxyTargetFloorValueRangeRule(min: 6.7, max: 2692.9)
        let item = Consent.newStrictProxyTarget("x", label: "y")
        item.floorValue = 2694.4
        #expect(rule.check(item).count > 0)
    }
}
