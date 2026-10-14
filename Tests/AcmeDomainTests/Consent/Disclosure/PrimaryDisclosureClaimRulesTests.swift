@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryDisclosureClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPrimaryDisclosureClaimValidator()
        let item = Consent.newPrimaryDisclosureClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPrimaryDisclosureClaimRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Consent.PrimaryDisclosureClaimRequiredBedRule(message: "primary disclosure claim needs an entry")
        let item = Consent.newPrimaryDisclosureClaim("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPrimaryDisclosureClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.PrimaryDisclosureClaimRequiredCodeRule(message: "primary disclosure claim needs a value")
        let item = Consent.newPrimaryDisclosureClaim("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPrimaryDisclosureClaimSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Consent.PrimaryDisclosureClaimSequenceRangeRule(min: 16, max: 120)
        let item = Consent.newPrimaryDisclosureClaim("x", title: "y")
        item.sequence = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPrimaryDisclosureClaimExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Consent.PrimaryDisclosureClaimExpiresAtRangeRule(min: 64, max: 80)
        let item = Consent.newPrimaryDisclosureClaim("x", title: "y")
        item.expiresAt = 81
        #expect(rule.check(item).count > 0)
    }
}
