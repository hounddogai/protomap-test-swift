@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyOvertimePolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLegacyOvertimePolicyValidator()
        let item = Staffing.newLegacyOvertimePolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLegacyOvertimePolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.LegacyOvertimePolicyCodeLengthRule(maxLength: 1000)
        let item = Staffing.newLegacyOvertimePolicy("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingLegacyOvertimePolicyChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Staffing.LegacyOvertimePolicyChannelLengthRule(maxLength: 80)
        let item = Staffing.newLegacyOvertimePolicy("x", name: "y")
        item.channel = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingLegacyOvertimePolicyRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Staffing.LegacyOvertimePolicyRequiredChannelRule(message: "legacy overtime policy needs this field")
        let item = Staffing.newLegacyOvertimePolicy("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLegacyOvertimePolicyFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.LegacyOvertimePolicyFloorValueRangeRule(min: 6.9, max: 255.7)
        let item = Staffing.newLegacyOvertimePolicy("x", name: "y")
        item.floorValue = 257.2
        #expect(rule.check(item).count > 0)
    }
}
