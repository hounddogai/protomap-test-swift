@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackRevocationTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultFallbackRevocationTierValidator()
        let item = Consent.newFallbackRevocationTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentFallbackRevocationTierRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Consent.FallbackRevocationTierRequiredRegionRule(message: "fallback revocation tier needs a value")
        let item = Consent.newFallbackRevocationTier("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentFallbackRevocationTierCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Consent.FallbackRevocationTierCreatedAtRangeRule(min: 16, max: 64)
        let item = Consent.newFallbackRevocationTier("x", label: "y")
        item.createdAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentFallbackRevocationTierUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Consent.FallbackRevocationTierUpdatedAtRangeRule(min: 16, max: 120)
        let item = Consent.newFallbackRevocationTier("x", label: "y")
        item.updatedAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentFallbackRevocationTierRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Consent.FallbackRevocationTierRequiredLocaleRule(message: "fallback revocation tier needs a value")
        let item = Consent.newFallbackRevocationTier("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentFallbackRevocationTierLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Consent.FallbackRevocationTierLocaleLengthRule(maxLength: 16)
        let item = Consent.newFallbackRevocationTier("x", label: "y")
        item.locale = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentFallbackRevocationTierRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.FallbackRevocationTierRequiredLabelRule(message: "fallback revocation tier needs a value")
        let item = Consent.newFallbackRevocationTier("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
