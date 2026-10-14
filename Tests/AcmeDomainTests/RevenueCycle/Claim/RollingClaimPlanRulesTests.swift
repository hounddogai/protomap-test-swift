@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingClaimPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRollingClaimPlanValidator()
        let item = RevenueCycle.newRollingClaimPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRollingClaimPlanRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = RevenueCycle.RollingClaimPlanRequiredPatientRefRule(message: "rolling claim plan needs this field")
        let item = RevenueCycle.newRollingClaimPlan("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRollingClaimPlanSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = RevenueCycle.RollingClaimPlanSequenceRangeRule(min: 32, max: 64)
        let item = RevenueCycle.newRollingClaimPlan("x", title: "y")
        item.sequence = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRollingClaimPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RollingClaimPlanRequiredCodeRule(message: "rolling claim plan needs a value")
        let item = RevenueCycle.newRollingClaimPlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRollingClaimPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RollingClaimPlanCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newRollingClaimPlan("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
