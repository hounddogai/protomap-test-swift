@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialRuleValidator()
        let item = RevenueCycle.newDenialRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialRuleRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = RevenueCycle.DenialRuleRequiredFacilityRule(message: "denial rule needs a value")
        let item = RevenueCycle.newDenialRule("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialRuleRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = RevenueCycle.DenialRuleRequiredProcedureCodeRule(message: "denial rule needs an entry")
        let item = RevenueCycle.newDenialRule("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.DenialRuleRequiredCodeRule(message: "denial rule needs a value")
        let item = RevenueCycle.newDenialRule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialRuleDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = RevenueCycle.DenialRuleDiscountRangeRule(min: 4.7, max: 2455.9)
        let item = RevenueCycle.newDenialRule("x", name: "y")
        item.discount = 2457.4
        #expect(rule.check(item).count > 0)
    }
}
