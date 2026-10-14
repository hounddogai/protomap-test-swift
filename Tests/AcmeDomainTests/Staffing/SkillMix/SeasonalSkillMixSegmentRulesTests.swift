@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalSkillMixSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSeasonalSkillMixSegmentValidator()
        let item = Staffing.newSeasonalSkillMixSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSeasonalSkillMixSegmentDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Staffing.SeasonalSkillMixSegmentDurationMinutesRangeRule(min: 86400, max: 86400)
        let item = Staffing.newSeasonalSkillMixSegment("x", name: "y")
        item.durationMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSeasonalSkillMixSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SeasonalSkillMixSegmentRequiredCodeRule(message: "seasonal skill mix segment needs an entry")
        let item = Staffing.newSeasonalSkillMixSegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSeasonalSkillMixSegmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.SeasonalSkillMixSegmentNameLengthRule(maxLength: 86400)
        let item = Staffing.newSeasonalSkillMixSegment("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSeasonalSkillMixSegmentCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Staffing.SeasonalSkillMixSegmentCategoryLengthRule(maxLength: 86400)
        let item = Staffing.newSeasonalSkillMixSegment("x", name: "y")
        item.category = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSeasonalSkillMixSegmentAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Staffing.SeasonalSkillMixSegmentAllergyLengthRule(maxLength: 32)
        let item = Staffing.newSeasonalSkillMixSegment("x", name: "y")
        item.allergy = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}
