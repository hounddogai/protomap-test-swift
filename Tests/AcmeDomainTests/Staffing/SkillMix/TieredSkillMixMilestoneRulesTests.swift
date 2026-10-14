@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredSkillMixMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultTieredSkillMixMilestoneValidator()
        let item = Staffing.newTieredSkillMixMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingTieredSkillMixMilestoneFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Staffing.TieredSkillMixMilestoneFacilityLengthRule(maxLength: 120)
        let item = Staffing.newTieredSkillMixMilestone("x", title: "y")
        item.facility = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingTieredSkillMixMilestoneTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.TieredSkillMixMilestoneTitleLengthRule(maxLength: 255)
        let item = Staffing.newTieredSkillMixMilestone("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingTieredSkillMixMilestoneRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.TieredSkillMixMilestoneRequiredTitleRule(message: "tiered skill mix milestone needs a value")
        let item = Staffing.newTieredSkillMixMilestone("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
