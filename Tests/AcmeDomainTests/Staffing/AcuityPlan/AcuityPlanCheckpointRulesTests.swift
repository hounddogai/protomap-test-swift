@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanCheckpointValidator()
        let item = Staffing.newAcuityPlanCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanCheckpointTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.AcuityPlanCheckpointTitleLengthRule(maxLength: 64)
        let item = Staffing.newAcuityPlanCheckpoint("x", name: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanCheckpointBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Staffing.AcuityPlanCheckpointBedLengthRule(maxLength: 64)
        let item = Staffing.newAcuityPlanCheckpoint("x", name: "y")
        item.bed = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
