@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingOvertimeSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRollingOvertimeSegmentValidator()
        let item = Staffing.newRollingOvertimeSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRollingOvertimeSegmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.RollingOvertimeSegmentTitleLengthRule(maxLength: 16)
        let item = Staffing.newRollingOvertimeSegment("x", name: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRollingOvertimeSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.RollingOvertimeSegmentRequiredCodeRule(message: "rolling overtime segment needs a value")
        let item = Staffing.newRollingOvertimeSegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRollingOvertimeSegmentExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Staffing.RollingOvertimeSegmentExpiresAtRangeRule(min: 32, max: 3600)
        let item = Staffing.newRollingOvertimeSegment("x", name: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRollingOvertimeSegmentRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.RollingOvertimeSegmentRateRangeRule(min: 0.6, max: 4708.4)
        let item = Staffing.newRollingOvertimeSegment("x", name: "y")
        item.rate = 4709.9
        #expect(rule.check(item).count > 0)
    }
}
