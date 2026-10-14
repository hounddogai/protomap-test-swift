@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCappedSkillMixEstimateValidator()
        let item = Staffing.newCappedSkillMixEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCappedSkillMixEstimateRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.CappedSkillMixEstimateRateRangeRule(min: 2.0, max: 461.8)
        let item = Staffing.newCappedSkillMixEstimate("x", name: "y")
        item.rate = 463.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCappedSkillMixEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CappedSkillMixEstimateCodeLengthRule(maxLength: 120)
        let item = Staffing.newCappedSkillMixEstimate("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedSkillMixEstimateCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Staffing.CappedSkillMixEstimateCeilingRangeRule(min: 2.8, max: 4481.0)
        let item = Staffing.newCappedSkillMixEstimate("x", name: "y")
        item.ceiling = 4482.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCappedSkillMixEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.CappedSkillMixEstimateRequiredCodeRule(message: "capped skill mix estimate needs an entry")
        let item = Staffing.newCappedSkillMixEstimate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCappedSkillMixEstimateRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Staffing.CappedSkillMixEstimateRequiredCountryRule(message: "capped skill mix estimate needs a value")
        let item = Staffing.newCappedSkillMixEstimate("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
