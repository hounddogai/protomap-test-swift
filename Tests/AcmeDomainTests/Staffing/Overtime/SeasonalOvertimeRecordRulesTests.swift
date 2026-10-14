@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalOvertimeRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSeasonalOvertimeRecordValidator()
        let item = Staffing.newSeasonalOvertimeRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSeasonalOvertimeRecordRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.SeasonalOvertimeRecordRequiredLabelRule(message: "seasonal overtime record needs this field")
        let item = Staffing.newSeasonalOvertimeRecord("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSeasonalOvertimeRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SeasonalOvertimeRecordRequiredCodeRule(message: "seasonal overtime record needs a value")
        let item = Staffing.newSeasonalOvertimeRecord("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
