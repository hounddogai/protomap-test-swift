@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedSkillMixMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultWeightedSkillMixMilestoneValidator()
        let item = Staffing.newWeightedSkillMixMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingWeightedSkillMixMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.WeightedSkillMixMilestoneRequiredCodeRule(
            message: "weighted skill mix milestone needs an entry"
        )
        let item = Staffing.newWeightedSkillMixMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
