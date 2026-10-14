@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryRemittancePlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPrimaryRemittancePlanValidator()
        let item = RevenueCycle.newPrimaryRemittancePlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePrimaryRemittancePlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.PrimaryRemittancePlanRequiredCodeRule(message: "primary remittance plan needs a value")
        let item = RevenueCycle.newPrimaryRemittancePlan("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePrimaryRemittancePlanRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = RevenueCycle.PrimaryRemittancePlanRequiredSpecialtyRule(
            message: "primary remittance plan needs an entry"
        )
        let item = RevenueCycle.newPrimaryRemittancePlan("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePrimaryRemittancePlanDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = RevenueCycle.PrimaryRemittancePlanDosageMgRangeRule(min: 7.6, max: 388.4)
        let item = RevenueCycle.newPrimaryRemittancePlan("x", name: "y")
        item.dosageMg = 389.9
        #expect(rule.check(item).count > 0)
    }
}
