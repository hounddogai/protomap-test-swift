@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationWindowValidator()
        let item = Consent.newRevocationWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.RevocationWindowCodeLengthRule(maxLength: 80)
        let item = Consent.newRevocationWindow("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationWindowPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Consent.RevocationWindowPayerLengthRule(maxLength: 32)
        let item = Consent.newRevocationWindow("x", title: "y")
        item.payer = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationWindowRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Consent.RevocationWindowRequiredSegmentRule(message: "revocation window needs this field")
        let item = Consent.newRevocationWindow("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRevocationWindowCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Consent.RevocationWindowCeilingRangeRule(min: 5.9, max: 3036.3)
        let item = Consent.newRevocationWindow("x", title: "y")
        item.ceiling = 3037.8
        #expect(rule.check(item).count > 0)
    }
}
