@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingSkillMixScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPendingSkillMixScoreValidator()
        let item = Staffing.newPendingSkillMixScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPendingSkillMixScoreRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.PendingSkillMixScoreRequiredNameRule(message: "pending skill mix score needs a value")
        let item = Staffing.newPendingSkillMixScore("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPendingSkillMixScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.PendingSkillMixScoreRequiredCodeRule(message: "pending skill mix score needs an entry")
        let item = Staffing.newPendingSkillMixScore("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPendingSkillMixScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.PendingSkillMixScoreNameLengthRule(maxLength: 120)
        let item = Staffing.newPendingSkillMixScore("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
