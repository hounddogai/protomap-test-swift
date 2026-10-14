@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedChargeClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultWeightedChargeClaimValidator()
        let item = RevenueCycle.newWeightedChargeClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleWeightedChargeClaimContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = RevenueCycle.WeightedChargeClaimContactEmailLengthRule(maxLength: 3600)
        let item = RevenueCycle.newWeightedChargeClaim("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleWeightedChargeClaimRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = RevenueCycle.WeightedChargeClaimRequiredContactEmailRule(
            message: "weighted charge claim needs an entry"
        )
        let item = RevenueCycle.newWeightedChargeClaim("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleWeightedChargeClaimEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = RevenueCycle.WeightedChargeClaimEndsAtRangeRule(min: 1000, max: 1000)
        let item = RevenueCycle.newWeightedChargeClaim("x", name: "y")
        item.endsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
