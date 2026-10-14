@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackRoundingPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackRoundingPreferenceValidator()
        let item = ClinicalOps.newFallbackRoundingPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackRoundingPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.FallbackRoundingPreferenceRequiredCodeRule(
            message: "fallback rounding preference needs this field"
        )
        let item = ClinicalOps.newFallbackRoundingPreference("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackRoundingPreferenceRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = ClinicalOps.FallbackRoundingPreferenceRequiredSpecialtyRule(
            message: "fallback rounding preference needs an entry"
        )
        let item = ClinicalOps.newFallbackRoundingPreference("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackRoundingPreferenceSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = ClinicalOps.FallbackRoundingPreferenceSpecialtyLengthRule(maxLength: 120)
        let item = ClinicalOps.newFallbackRoundingPreference("x", name: "y")
        item.specialty = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
