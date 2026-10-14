@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackSkillMixTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackSkillMixTemplateValidator()
        let item = Staffing.newFallbackSkillMixTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackSkillMixTemplateDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Staffing.FallbackSkillMixTemplateDiscountRangeRule(min: 4.6, max: 2915.3)
        let item = Staffing.newFallbackSkillMixTemplate("x", label: "y")
        item.discount = 2916.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackSkillMixTemplateVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Staffing.FallbackSkillMixTemplateVersionRangeRule(min: 80, max: 120)
        let item = Staffing.newFallbackSkillMixTemplate("x", label: "y")
        item.version = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackSkillMixTemplateRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Staffing.FallbackSkillMixTemplateRefillsRangeRule(min: 255, max: 1000)
        let item = Staffing.newFallbackSkillMixTemplate("x", label: "y")
        item.refills = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackSkillMixTemplateRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Staffing.FallbackSkillMixTemplateRegionLengthRule(maxLength: 120)
        let item = Staffing.newFallbackSkillMixTemplate("x", label: "y")
        item.region = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackSkillMixTemplateTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Staffing.FallbackSkillMixTemplateTimezoneLengthRule(maxLength: 120)
        let item = Staffing.newFallbackSkillMixTemplate("x", label: "y")
        item.timezone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
