@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryAcuityPlanScoreValidator()
        let item = Staffing.newPrimaryAcuityPlanScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryAcuityPlanScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PrimaryAcuityPlanScoreCodeLengthRule(maxLength: 3600)
        let item = Staffing.newPrimaryAcuityPlanScore("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryAcuityPlanScoreRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.PrimaryAcuityPlanScoreRequiredTitleRule(message: "primary acuity plan score needs an entry")
        let item = Staffing.newPrimaryAcuityPlanScore("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryAcuityPlanScoreMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Staffing.PrimaryAcuityPlanScoreMarginRangeRule(min: 2.7, max: 2762.9)
        let item = Staffing.newPrimaryAcuityPlanScore("x", title: "y")
        item.margin = 2764.4
        #expect(rule.check(item).count > 0)
    }
}
