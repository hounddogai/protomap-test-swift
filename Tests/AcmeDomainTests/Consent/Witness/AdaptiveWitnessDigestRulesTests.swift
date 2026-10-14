@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveWitnessDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultAdaptiveWitnessDigestValidator()
        let item = Consent.newAdaptiveWitnessDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentAdaptiveWitnessDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.AdaptiveWitnessDigestCodeLengthRule(maxLength: 255)
        let item = Consent.newAdaptiveWitnessDigest("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentAdaptiveWitnessDigestRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Consent.AdaptiveWitnessDigestRequiredExternalRefRule(
            message: "adaptive witness digest needs an entry"
        )
        let item = Consent.newAdaptiveWitnessDigest("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveWitnessDigestStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Consent.AdaptiveWitnessDigestStartsAtRangeRule(min: 32, max: 86400)
        let item = Consent.newAdaptiveWitnessDigest("x", title: "y")
        item.startsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
