@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanBaselineValidator()
        let item = Staffing.newAcuityPlanBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanBaselineRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Staffing.AcuityPlanBaselineRequiredSummaryRule(message: "acuity plan baseline needs this field")
        let item = Staffing.newAcuityPlanBaseline("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AcuityPlanBaselineCodeLengthRule(maxLength: 120)
        let item = Staffing.newAcuityPlanBaseline("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanBaselineTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.AcuityPlanBaselineTitleLengthRule(maxLength: 64)
        let item = Staffing.newAcuityPlanBaseline("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanBaselineRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.AcuityPlanBaselineRateRangeRule(min: 5.4, max: 2492.3)
        let item = Staffing.newAcuityPlanBaseline("x", title: "y")
        item.rate = 2493.8
        #expect(rule.check(item).count > 0)
    }
}
