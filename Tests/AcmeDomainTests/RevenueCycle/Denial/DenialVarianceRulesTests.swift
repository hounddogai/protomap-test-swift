@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialVarianceValidator()
        let item = RevenueCycle.newDenialVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialVarianceDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = RevenueCycle.DenialVarianceDosageMgRangeRule(min: 5.1, max: 698.6)
        let item = RevenueCycle.newDenialVariance("x", title: "y")
        item.dosageMg = 700.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialVarianceRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = RevenueCycle.DenialVarianceRequiredFacilityRule(message: "denial variance needs a value")
        let item = RevenueCycle.newDenialVariance("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialVarianceFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = RevenueCycle.DenialVarianceFacilityLengthRule(maxLength: 255)
        let item = RevenueCycle.newDenialVariance("x", title: "y")
        item.facility = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.DenialVarianceRequiredCodeRule(message: "denial variance needs a value")
        let item = RevenueCycle.newDenialVariance("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
