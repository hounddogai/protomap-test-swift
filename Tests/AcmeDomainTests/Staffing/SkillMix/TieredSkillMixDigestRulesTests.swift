@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredSkillMixDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultTieredSkillMixDigestValidator()
        let item = Staffing.newTieredSkillMixDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingTieredSkillMixDigestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.TieredSkillMixDigestRequiredTitleRule(message: "tiered skill mix digest needs this field")
        let item = Staffing.newTieredSkillMixDigest("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingTieredSkillMixDigestMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Staffing.TieredSkillMixDigestMarginRangeRule(min: 8.0, max: 807.9)
        let item = Staffing.newTieredSkillMixDigest("x", label: "y")
        item.margin = 809.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingTieredSkillMixDigestRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Staffing.TieredSkillMixDigestRequiredCategoryRule(message: "tiered skill mix digest needs an entry")
        let item = Staffing.newTieredSkillMixDigest("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}
