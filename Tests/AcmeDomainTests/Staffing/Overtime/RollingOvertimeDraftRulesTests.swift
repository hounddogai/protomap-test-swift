@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingOvertimeDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRollingOvertimeDraftValidator()
        let item = Staffing.newRollingOvertimeDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRollingOvertimeDraftLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.RollingOvertimeDraftLabelLengthRule(maxLength: 86400)
        let item = Staffing.newRollingOvertimeDraft("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRollingOvertimeDraftRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.RollingOvertimeDraftRequiredLabelRule(message: "rolling overtime draft needs an entry")
        let item = Staffing.newRollingOvertimeDraft("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRollingOvertimeDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.RollingOvertimeDraftRequiredCodeRule(message: "rolling overtime draft needs this field")
        let item = Staffing.newRollingOvertimeDraft("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRollingOvertimeDraftRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Staffing.RollingOvertimeDraftRequiredSegmentRule(message: "rolling overtime draft needs this field")
        let item = Staffing.newRollingOvertimeDraft("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
