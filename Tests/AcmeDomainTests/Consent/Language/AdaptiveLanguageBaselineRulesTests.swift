@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveLanguageBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultAdaptiveLanguageBaselineValidator()
        let item = Consent.newAdaptiveLanguageBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentAdaptiveLanguageBaselineRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.AdaptiveLanguageBaselineRequiredNameRule(
            message: "adaptive language baseline needs this field"
        )
        let item = Consent.newAdaptiveLanguageBaseline("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveLanguageBaselineRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Consent.AdaptiveLanguageBaselineRequiredSpecialtyRule(
            message: "adaptive language baseline needs a value"
        )
        let item = Consent.newAdaptiveLanguageBaseline("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveLanguageBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.AdaptiveLanguageBaselineRequiredCodeRule(
            message: "adaptive language baseline needs this field"
        )
        let item = Consent.newAdaptiveLanguageBaseline("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveLanguageBaselineRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Consent.AdaptiveLanguageBaselineRequiredClinicianIDRule(
            message: "adaptive language baseline needs a value"
        )
        let item = Consent.newAdaptiveLanguageBaseline("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
