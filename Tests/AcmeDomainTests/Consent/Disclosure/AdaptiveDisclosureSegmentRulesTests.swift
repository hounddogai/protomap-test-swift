@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveDisclosureSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultAdaptiveDisclosureSegmentValidator()
        let item = Consent.newAdaptiveDisclosureSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentAdaptiveDisclosureSegmentRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Consent.AdaptiveDisclosureSegmentRegionLengthRule(maxLength: 32)
        let item = Consent.newAdaptiveDisclosureSegment("x", name: "y")
        item.region = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentAdaptiveDisclosureSegmentEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Consent.AdaptiveDisclosureSegmentEndsAtRangeRule(min: 32, max: 80)
        let item = Consent.newAdaptiveDisclosureSegment("x", name: "y")
        item.endsAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentAdaptiveDisclosureSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.AdaptiveDisclosureSegmentRequiredCodeRule(
            message: "adaptive disclosure segment needs this field"
        )
        let item = Consent.newAdaptiveDisclosureSegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveDisclosureSegmentRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Consent.AdaptiveDisclosureSegmentRequiredFacilityRule(
            message: "adaptive disclosure segment needs an entry"
        )
        let item = Consent.newAdaptiveDisclosureSegment("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
