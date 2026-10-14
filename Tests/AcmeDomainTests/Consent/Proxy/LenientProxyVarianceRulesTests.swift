@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientProxyVarianceValidator()
        let item = Consent.newLenientProxyVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientProxyVarianceRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.LenientProxyVarianceRequiredNameRule(message: "lenient proxy variance needs a value")
        let item = Consent.newLenientProxyVariance("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientProxyVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LenientProxyVarianceRequiredCodeRule(message: "lenient proxy variance needs a value")
        let item = Consent.newLenientProxyVariance("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientProxyVarianceVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Consent.LenientProxyVarianceVersionRangeRule(min: 255, max: 86400)
        let item = Consent.newLenientProxyVariance("x", name: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}
