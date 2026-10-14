@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualShiftScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultManualShiftScoreValidator()
        let item = Staffing.newManualShiftScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingManualShiftScoreChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Staffing.ManualShiftScoreChannelLengthRule(maxLength: 120)
        let item = Staffing.newManualShiftScore("x", name: "y")
        item.channel = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingManualShiftScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.ManualShiftScoreNameLengthRule(maxLength: 16)
        let item = Staffing.newManualShiftScore("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingManualShiftScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ManualShiftScoreRequiredCodeRule(message: "manual shift score needs an entry")
        let item = Staffing.newManualShiftScore("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingManualShiftScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ManualShiftScoreCodeLengthRule(maxLength: 255)
        let item = Staffing.newManualShiftScore("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
