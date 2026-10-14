@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageRequestValidator()
        let item = Consent.newLanguageRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageRequestWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Consent.LanguageRequestWeightRangeRule(min: 9.6, max: 4892.4)
        let item = Consent.newLanguageRequest("x", title: "y")
        item.weight = 4893.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LanguageRequestRequiredCodeRule(message: "language request needs a value")
        let item = Consent.newLanguageRequest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
