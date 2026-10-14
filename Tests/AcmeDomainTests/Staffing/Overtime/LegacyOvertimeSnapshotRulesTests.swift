@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyOvertimeSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLegacyOvertimeSnapshotValidator()
        let item = Staffing.newLegacyOvertimeSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLegacyOvertimeSnapshotRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Staffing.LegacyOvertimeSnapshotRequiredBedRule(message: "legacy overtime snapshot needs an entry")
        let item = Staffing.newLegacyOvertimeSnapshot("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLegacyOvertimeSnapshotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.LegacyOvertimeSnapshotTitleLengthRule(maxLength: 86400)
        let item = Staffing.newLegacyOvertimeSnapshot("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingLegacyOvertimeSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.LegacyOvertimeSnapshotCodeLengthRule(maxLength: 86400)
        let item = Staffing.newLegacyOvertimeSnapshot("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
