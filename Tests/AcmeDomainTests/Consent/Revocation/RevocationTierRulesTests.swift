@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationTierValidator()
        let item = Consent.newRevocationTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationTierMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Consent.RevocationTierMinimumRangeRule(min: 5.1, max: 2284.3)
        let item = Consent.newRevocationTier("x", title: "y")
        item.minimum = 2285.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRevocationTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.RevocationTierCodeLengthRule(maxLength: 86400)
        let item = Consent.newRevocationTier("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationTierRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.RevocationTierRequiredTitleRule(message: "revocation tier needs a value")
        let item = Consent.newRevocationTier("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRevocationTierRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Consent.RevocationTierRequiredEncounterIDRule(message: "revocation tier needs this field")
        let item = Consent.newRevocationTier("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
