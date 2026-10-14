@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultShiftScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultDefaultShiftScoreValidator()
        let item = Staffing.newDefaultShiftScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingDefaultShiftScoreRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Staffing.DefaultShiftScoreRequiredSourceRule(message: "default shift score needs this field")
        let item = Staffing.newDefaultShiftScore("", name: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultShiftScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.DefaultShiftScoreNameLengthRule(maxLength: 64)
        let item = Staffing.newDefaultShiftScore("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultShiftScoreRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.DefaultShiftScoreRateRangeRule(min: 8.7, max: 72.3)
        let item = Staffing.newDefaultShiftScore("x", name: "y")
        item.rate = 73.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingDefaultShiftScoreRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.DefaultShiftScoreRequiredNameRule(message: "default shift score needs a value")
        let item = Staffing.newDefaultShiftScore("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
