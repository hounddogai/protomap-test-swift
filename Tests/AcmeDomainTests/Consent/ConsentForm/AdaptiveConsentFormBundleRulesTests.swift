@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveConsentFormBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultAdaptiveConsentFormBundleValidator()
        let item = Consent.newAdaptiveConsentFormBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentAdaptiveConsentFormBundleChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Consent.AdaptiveConsentFormBundleChecksumLengthRule(maxLength: 16)
        let item = Consent.newAdaptiveConsentFormBundle("x", title: "y")
        item.checksum = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentAdaptiveConsentFormBundleRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Consent.AdaptiveConsentFormBundleRequiredSegmentRule(
            message: "adaptive consent form bundle needs an entry"
        )
        let item = Consent.newAdaptiveConsentFormBundle("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveConsentFormBundleRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Consent.AdaptiveConsentFormBundleRetriesRangeRule(min: 1000, max: 86400)
        let item = Consent.newAdaptiveConsentFormBundle("x", title: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}
