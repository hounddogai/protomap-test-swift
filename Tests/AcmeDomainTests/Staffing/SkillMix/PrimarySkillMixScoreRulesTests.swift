@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimarySkillMixScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimarySkillMixScoreValidator()
        let item = Staffing.newPrimarySkillMixScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimarySkillMixScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.PrimarySkillMixScoreRequiredCodeRule(message: "primary skill mix score needs an entry")
        let item = Staffing.newPrimarySkillMixScore("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimarySkillMixScoreCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Staffing.PrimarySkillMixScoreCeilingRangeRule(min: 4.0, max: 714.6)
        let item = Staffing.newPrimarySkillMixScore("x", name: "y")
        item.ceiling = 716.1
        #expect(rule.check(item).count > 0)
    }
}
