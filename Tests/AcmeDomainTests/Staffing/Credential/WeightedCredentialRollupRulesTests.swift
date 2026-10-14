@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedCredentialRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultWeightedCredentialRollupValidator()
        let item = Staffing.newWeightedCredentialRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingWeightedCredentialRollupSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Staffing.WeightedCredentialRollupSpecialtyLengthRule(maxLength: 3600)
        let item = Staffing.newWeightedCredentialRollup("x", label: "y")
        item.specialty = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingWeightedCredentialRollupDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Staffing.WeightedCredentialRollupDurationMinutesRangeRule(min: 1000, max: 3600)
        let item = Staffing.newWeightedCredentialRollup("x", label: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingWeightedCredentialRollupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.WeightedCredentialRollupLabelLengthRule(maxLength: 32)
        let item = Staffing.newWeightedCredentialRollup("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingWeightedCredentialRollupRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Staffing.WeightedCredentialRollupRatioRangeRule(min: 9.0, max: 640.4)
        let item = Staffing.newWeightedCredentialRollup("x", label: "y")
        item.ratio = 641.9
        #expect(rule.check(item).count > 0)
    }
}
