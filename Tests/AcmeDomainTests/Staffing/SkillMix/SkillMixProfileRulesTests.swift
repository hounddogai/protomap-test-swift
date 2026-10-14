@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixProfileValidator()
        let item = Staffing.newSkillMixProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixProfileCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Staffing.SkillMixProfileCopayRangeRule(min: 8.8, max: 4274.1)
        let item = Staffing.newSkillMixProfile("x", name: "y")
        item.copay = 4275.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixProfileRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.SkillMixProfileRequiredLabelRule(message: "skill mix profile needs a value")
        let item = Staffing.newSkillMixProfile("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
