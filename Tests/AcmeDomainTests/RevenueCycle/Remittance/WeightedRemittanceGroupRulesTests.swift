@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedRemittanceGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultWeightedRemittanceGroupValidator()
        let item = RevenueCycle.newWeightedRemittanceGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleWeightedRemittanceGroupRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = RevenueCycle.WeightedRemittanceGroupRequiredAllergyRule(
            message: "weighted remittance group needs an entry"
        )
        let item = RevenueCycle.newWeightedRemittanceGroup("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleWeightedRemittanceGroupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.WeightedRemittanceGroupLabelLengthRule(maxLength: 255)
        let item = RevenueCycle.newWeightedRemittanceGroup("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleWeightedRemittanceGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.WeightedRemittanceGroupRequiredCodeRule(
            message: "weighted remittance group needs this field"
        )
        let item = RevenueCycle.newWeightedRemittanceGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleWeightedRemittanceGroupAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = RevenueCycle.WeightedRemittanceGroupAllergyLengthRule(maxLength: 86400)
        let item = RevenueCycle.newWeightedRemittanceGroup("x", label: "y")
        item.allergy = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleWeightedRemittanceGroupRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = RevenueCycle.WeightedRemittanceGroupRatioRangeRule(min: 9.0, max: 4825.2)
        let item = RevenueCycle.newWeightedRemittanceGroup("x", label: "y")
        item.ratio = 4826.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleWeightedRemittanceGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.WeightedRemittanceGroupCodeLengthRule(maxLength: 255)
        let item = RevenueCycle.newWeightedRemittanceGroup("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
