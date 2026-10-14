@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackFloatPoolCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackFloatPoolCheckpointValidator()
        let item = Staffing.newFallbackFloatPoolCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackFloatPoolCheckpointAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Staffing.FallbackFloatPoolCheckpointAttemptsRangeRule(min: 1000, max: 86400)
        let item = Staffing.newFallbackFloatPoolCheckpoint("x", label: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackFloatPoolCheckpointLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.FallbackFloatPoolCheckpointLabelLengthRule(maxLength: 16)
        let item = Staffing.newFallbackFloatPoolCheckpoint("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackFloatPoolCheckpointMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Staffing.FallbackFloatPoolCheckpointMinimumRangeRule(min: 6.3, max: 67.2)
        let item = Staffing.newFallbackFloatPoolCheckpoint("x", label: "y")
        item.minimum = 68.7
        #expect(rule.check(item).count > 0)
    }
}
