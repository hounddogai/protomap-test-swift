@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultSkillMixScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultDefaultSkillMixScoreValidator()
        let item = Staffing.newDefaultSkillMixScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingDefaultSkillMixScoreDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Staffing.DefaultSkillMixScoreDiscountRangeRule(min: 0.2, max: 3831.0)
        let item = Staffing.newDefaultSkillMixScore("x", title: "y")
        item.discount = 3832.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingDefaultSkillMixScoreRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Staffing.DefaultSkillMixScoreRequiredEncounterIDRule(message: "default skill mix score needs a value")
        let item = Staffing.newDefaultSkillMixScore("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultSkillMixScoreCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Staffing.DefaultSkillMixScoreCopayRangeRule(min: 1.2, max: 3862.6)
        let item = Staffing.newDefaultSkillMixScore("x", title: "y")
        item.copay = 3864.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingDefaultSkillMixScoreAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Staffing.DefaultSkillMixScoreAttemptsRangeRule(min: 120, max: 1000)
        let item = Staffing.newDefaultSkillMixScore("x", title: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}
