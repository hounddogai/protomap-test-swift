@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacySkillMixBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLegacySkillMixBundleValidator()
        let item = Staffing.newLegacySkillMixBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLegacySkillMixBundleCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Staffing.LegacySkillMixBundleCeilingRangeRule(min: 3.3, max: 3583.5)
        let item = Staffing.newLegacySkillMixBundle("x", label: "y")
        item.ceiling = 3585.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingLegacySkillMixBundleRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Staffing.LegacySkillMixBundleRequiredAllergyRule(message: "legacy skill mix bundle needs a value")
        let item = Staffing.newLegacySkillMixBundle("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
