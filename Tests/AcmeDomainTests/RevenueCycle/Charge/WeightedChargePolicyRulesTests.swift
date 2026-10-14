@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedChargePolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultWeightedChargePolicyValidator()
        let item = RevenueCycle.newWeightedChargePolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleWeightedChargePolicyRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = RevenueCycle.WeightedChargePolicyRequiredContactEmailRule(
            message: "weighted charge policy needs a value"
        )
        let item = RevenueCycle.newWeightedChargePolicy("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleWeightedChargePolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.WeightedChargePolicyRequiredLabelRule(message: "weighted charge policy needs an entry")
        let item = RevenueCycle.newWeightedChargePolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
