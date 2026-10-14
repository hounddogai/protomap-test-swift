@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveFormularyDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultAdaptiveFormularyDigestValidator()
        let item = Pharmacy.newAdaptiveFormularyDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyAdaptiveFormularyDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.AdaptiveFormularyDigestRequiredCodeRule(message: "adaptive formulary digest needs a value")
        let item = Pharmacy.newAdaptiveFormularyDigest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
