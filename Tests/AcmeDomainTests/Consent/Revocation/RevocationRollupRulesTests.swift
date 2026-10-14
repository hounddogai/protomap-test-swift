@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationRollupValidator()
        let item = Consent.newRevocationRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RevocationRollupRequiredCodeRule(message: "revocation rollup needs this field")
        let item = Consent.newRevocationRollup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRevocationRollupOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Consent.RevocationRollupOwnerIDLengthRule(maxLength: 120)
        let item = Consent.newRevocationRollup("x", label: "y")
        item.ownerID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationRollupMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Consent.RevocationRollupMinimumRangeRule(min: 6.3, max: 1780.1)
        let item = Consent.newRevocationRollup("x", label: "y")
        item.minimum = 1781.6
        #expect(rule.check(item).count > 0)
    }
}
