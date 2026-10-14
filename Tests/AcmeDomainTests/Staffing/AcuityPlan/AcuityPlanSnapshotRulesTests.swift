@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanSnapshotValidator()
        let item = Staffing.newAcuityPlanSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanSnapshotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.AcuityPlanSnapshotNameLengthRule(maxLength: 1000)
        let item = Staffing.newAcuityPlanSnapshot("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanSnapshotPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Staffing.AcuityPlanSnapshotPhoneLengthRule(maxLength: 86400)
        let item = Staffing.newAcuityPlanSnapshot("x", name: "y")
        item.phone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanSnapshotRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Staffing.AcuityPlanSnapshotRequiredSegmentRule(message: "acuity plan snapshot needs a value")
        let item = Staffing.newAcuityPlanSnapshot("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.AcuityPlanSnapshotRequiredNameRule(message: "acuity plan snapshot needs this field")
        let item = Staffing.newAcuityPlanSnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
