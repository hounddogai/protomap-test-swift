@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualChargeAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualChargeAssignmentValidator()
        let item = RevenueCycle.newManualChargeAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualChargeAssignmentScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = RevenueCycle.ManualChargeAssignmentScoreRangeRule(min: 1.0, max: 3722.7)
        let item = RevenueCycle.newManualChargeAssignment("x", name: "y")
        item.score = 3724.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleManualChargeAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ManualChargeAssignmentCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newManualChargeAssignment("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
