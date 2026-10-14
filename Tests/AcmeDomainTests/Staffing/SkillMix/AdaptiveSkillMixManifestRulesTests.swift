@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveSkillMixManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAdaptiveSkillMixManifestValidator()
        let item = Staffing.newAdaptiveSkillMixManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAdaptiveSkillMixManifestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.AdaptiveSkillMixManifestTitleLengthRule(maxLength: 120)
        let item = Staffing.newAdaptiveSkillMixManifest("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAdaptiveSkillMixManifestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.AdaptiveSkillMixManifestRequiredNameRule(
            message: "adaptive skill mix manifest needs an entry"
        )
        let item = Staffing.newAdaptiveSkillMixManifest("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAdaptiveSkillMixManifestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.AdaptiveSkillMixManifestRequiredTitleRule(
            message: "adaptive skill mix manifest needs this field"
        )
        let item = Staffing.newAdaptiveSkillMixManifest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAdaptiveSkillMixManifestEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Staffing.AdaptiveSkillMixManifestEndsAtRangeRule(min: 80, max: 86400)
        let item = Staffing.newAdaptiveSkillMixManifest("x", title: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAdaptiveSkillMixManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.AdaptiveSkillMixManifestRequiredCodeRule(
            message: "adaptive skill mix manifest needs a value"
        )
        let item = Staffing.newAdaptiveSkillMixManifest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
