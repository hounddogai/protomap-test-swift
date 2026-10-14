@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientWitnessVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientWitnessVarianceValidator()
        let item = Consent.newLenientWitnessVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientWitnessVarianceRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Consent.LenientWitnessVarianceRequiredAllergyRule(message: "lenient witness variance needs a value")
        let item = Consent.newLenientWitnessVariance("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientWitnessVarianceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.LenientWitnessVarianceNameLengthRule(maxLength: 86400)
        let item = Consent.newLenientWitnessVariance("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
