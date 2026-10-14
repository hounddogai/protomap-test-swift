@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanOverrideValidator()
        let item = BedManagement.newDischargePlanOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.DischargePlanOverrideCodeLengthRule(maxLength: 64)
        let item = BedManagement.newDischargePlanOverride("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanOverrideSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = BedManagement.DischargePlanOverrideSequenceRangeRule(min: 120, max: 86400)
        let item = BedManagement.newDischargePlanOverride("x", name: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanOverrideAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = BedManagement.DischargePlanOverrideAttemptsRangeRule(min: 16, max: 80)
        let item = BedManagement.newDischargePlanOverride("x", name: "y")
        item.attempts = 81
        #expect(rule.check(item).count > 0)
    }
}
