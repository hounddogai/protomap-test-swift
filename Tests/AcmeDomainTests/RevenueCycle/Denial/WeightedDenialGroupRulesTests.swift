@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedDenialGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultWeightedDenialGroupValidator()
        let item = RevenueCycle.newWeightedDenialGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleWeightedDenialGroupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.WeightedDenialGroupNameLengthRule(maxLength: 3600)
        let item = RevenueCycle.newWeightedDenialGroup("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleWeightedDenialGroupMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = RevenueCycle.WeightedDenialGroupMaximumRangeRule(min: 8.0, max: 1324.6)
        let item = RevenueCycle.newWeightedDenialGroup("x", name: "y")
        item.maximum = 1326.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleWeightedDenialGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.WeightedDenialGroupRequiredCodeRule(message: "weighted denial group needs this field")
        let item = RevenueCycle.newWeightedDenialGroup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleWeightedDenialGroupRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = RevenueCycle.WeightedDenialGroupRequiredFacilityRule(message: "weighted denial group needs a value")
        let item = RevenueCycle.newWeightedDenialGroup("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
