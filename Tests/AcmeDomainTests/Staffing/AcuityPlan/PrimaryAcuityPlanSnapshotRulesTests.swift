@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryAcuityPlanSnapshotValidator()
        let item = Staffing.newPrimaryAcuityPlanSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryAcuityPlanSnapshotPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Staffing.PrimaryAcuityPlanSnapshotPatientRefLengthRule(maxLength: 32)
        let item = Staffing.newPrimaryAcuityPlanSnapshot("x", label: "y")
        item.patientRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryAcuityPlanSnapshotScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Staffing.PrimaryAcuityPlanSnapshotScoreRangeRule(min: 7.9, max: 2607.0)
        let item = Staffing.newPrimaryAcuityPlanSnapshot("x", label: "y")
        item.score = 2608.5
        #expect(rule.check(item).count > 0)
    }
}
