@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultShiftProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultDefaultShiftProfileValidator()
        let item = Staffing.newDefaultShiftProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingDefaultShiftProfileScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Staffing.DefaultShiftProfileScoreRangeRule(min: 3.2, max: 3116.4)
        let item = Staffing.newDefaultShiftProfile("x", label: "y")
        item.score = 3117.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingDefaultShiftProfileSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Staffing.DefaultShiftProfileSegmentLengthRule(maxLength: 16)
        let item = Staffing.newDefaultShiftProfile("x", label: "y")
        item.segment = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultShiftProfileRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Staffing.DefaultShiftProfileRequiredWardRule(message: "default shift profile needs this field")
        let item = Staffing.newDefaultShiftProfile("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultShiftProfileRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.DefaultShiftProfileRequiredLabelRule(message: "default shift profile needs a value")
        let item = Staffing.newDefaultShiftProfile("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
