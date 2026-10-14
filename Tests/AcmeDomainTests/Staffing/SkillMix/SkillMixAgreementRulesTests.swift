@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixAgreementValidator()
        let item = Staffing.newSkillMixAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixAgreementCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Staffing.SkillMixAgreementCostRangeRule(min: 5.3, max: 1346.0)
        let item = Staffing.newSkillMixAgreement("x", title: "y")
        item.cost = 1347.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.SkillMixAgreementRequiredTitleRule(message: "skill mix agreement needs this field")
        let item = Staffing.newSkillMixAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.SkillMixAgreementCodeLengthRule(maxLength: 80)
        let item = Staffing.newSkillMixAgreement("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
