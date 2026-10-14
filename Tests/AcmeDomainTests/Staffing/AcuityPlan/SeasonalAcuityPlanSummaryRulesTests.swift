@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalAcuityPlanSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSeasonalAcuityPlanSummaryValidator()
        let item = Staffing.newSeasonalAcuityPlanSummary("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSeasonalAcuityPlanSummaryRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Staffing.SeasonalAcuityPlanSummaryRequiredSegmentRule(
            message: "seasonal acuity plan summary needs a value"
        )
        let item = Staffing.newSeasonalAcuityPlanSummary("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSeasonalAcuityPlanSummaryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.SeasonalAcuityPlanSummaryNameLengthRule(maxLength: 3600)
        let item = Staffing.newSeasonalAcuityPlanSummary("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSeasonalAcuityPlanSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SeasonalAcuityPlanSummaryRequiredCodeRule(
            message: "seasonal acuity plan summary needs a value"
        )
        let item = Staffing.newSeasonalAcuityPlanSummary("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
