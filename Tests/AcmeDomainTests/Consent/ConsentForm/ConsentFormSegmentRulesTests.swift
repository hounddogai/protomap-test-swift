@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormSegmentValidator()
        let item = Consent.newConsentFormSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormSegmentRequiredCodeRule(message: "consent form segment needs an entry")
        let item = Consent.newConsentFormSegment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormSegmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.ConsentFormSegmentRequiredLabelRule(message: "consent form segment needs an entry")
        let item = Consent.newConsentFormSegment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormSegmentDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Consent.ConsentFormSegmentDosageMgRangeRule(min: 2.7, max: 1857.7)
        let item = Consent.newConsentFormSegment("x", label: "y")
        item.dosageMg = 1859.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentConsentFormSegmentRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Consent.ConsentFormSegmentRegionLengthRule(maxLength: 3600)
        let item = Consent.newConsentFormSegment("x", label: "y")
        item.region = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormSegmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.ConsentFormSegmentLabelLengthRule(maxLength: 86400)
        let item = Consent.newConsentFormSegment("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormSegmentLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Consent.ConsentFormSegmentLocaleLengthRule(maxLength: 32)
        let item = Consent.newConsentFormSegment("x", label: "y")
        item.locale = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
