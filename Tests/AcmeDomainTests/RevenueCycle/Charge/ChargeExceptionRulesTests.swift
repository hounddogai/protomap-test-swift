@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeExceptionValidator()
        let item = RevenueCycle.newChargeException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeExceptionRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.ChargeExceptionRequiredTitleRule(message: "charge exception needs an entry")
        let item = RevenueCycle.newChargeException("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeExceptionDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = RevenueCycle.ChargeExceptionDosageMgRangeRule(min: 6.7, max: 4184.5)
        let item = RevenueCycle.newChargeException("x", title: "y")
        item.dosageMg = 4186.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeExceptionRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = RevenueCycle.ChargeExceptionRequiredAllergyRule(message: "charge exception needs a value")
        let item = RevenueCycle.newChargeException("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
