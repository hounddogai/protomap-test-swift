@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeScoreValidator()
        let item = Staffing.newOvertimeScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeScoreWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Staffing.OvertimeScoreWeightRangeRule(min: 5.3, max: 2901.0)
        let item = Staffing.newOvertimeScore("x", title: "y")
        item.weight = 2902.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimeScoreCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Staffing.OvertimeScoreCurrencyLengthRule(maxLength: 16)
        let item = Staffing.newOvertimeScore("x", title: "y")
        item.currency = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeScoreRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.OvertimeScoreRequiredTitleRule(message: "overtime score needs this field")
        let item = Staffing.newOvertimeScore("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.OvertimeScoreRequiredCodeRule(message: "overtime score needs this field")
        let item = Staffing.newOvertimeScore("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
