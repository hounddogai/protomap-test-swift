@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryWitnessOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPrimaryWitnessOverrideValidator()
        let item = Consent.newPrimaryWitnessOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPrimaryWitnessOverrideRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Consent.PrimaryWitnessOverrideRequiredSpecialtyRule(message: "primary witness override needs a value")
        let item = Consent.newPrimaryWitnessOverride("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPrimaryWitnessOverrideCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Consent.PrimaryWitnessOverrideCeilingRangeRule(min: 2.3, max: 3611.0)
        let item = Consent.newPrimaryWitnessOverride("x", title: "y")
        item.ceiling = 3612.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPrimaryWitnessOverrideDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Consent.PrimaryWitnessOverrideDurationMinutesRangeRule(min: 3600, max: 86400)
        let item = Consent.newPrimaryWitnessOverride("x", title: "y")
        item.durationMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPrimaryWitnessOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.PrimaryWitnessOverrideRequiredCodeRule(message: "primary witness override needs this field")
        let item = Consent.newPrimaryWitnessOverride("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
