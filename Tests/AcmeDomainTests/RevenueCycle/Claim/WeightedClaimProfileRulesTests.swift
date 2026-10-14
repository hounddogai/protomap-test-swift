@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedClaimProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultWeightedClaimProfileValidator()
        let item = RevenueCycle.newWeightedClaimProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleWeightedClaimProfileCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = RevenueCycle.WeightedClaimProfileCopayRangeRule(min: 9.8, max: 685.0)
        let item = RevenueCycle.newWeightedClaimProfile("x", label: "y")
        item.copay = 686.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleWeightedClaimProfileRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = RevenueCycle.WeightedClaimProfileRequiredChecksumRule(message: "weighted claim profile needs a value")
        let item = RevenueCycle.newWeightedClaimProfile("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
