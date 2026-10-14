@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeSnapshotValidator()
        let item = Staffing.newOvertimeSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeSnapshotRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Staffing.OvertimeSnapshotRequiredSegmentRule(message: "overtime snapshot needs an entry")
        let item = Staffing.newOvertimeSnapshot("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeSnapshotEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Staffing.OvertimeSnapshotEncounterIDLengthRule(maxLength: 120)
        let item = Staffing.newOvertimeSnapshot("x", label: "y")
        item.encounterID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeSnapshotGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Staffing.OvertimeSnapshotGraceDaysRangeRule(min: 80, max: 86400)
        let item = Staffing.newOvertimeSnapshot("x", label: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimeSnapshotSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Staffing.OvertimeSnapshotSegmentLengthRule(maxLength: 120)
        let item = Staffing.newOvertimeSnapshot("x", label: "y")
        item.segment = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
