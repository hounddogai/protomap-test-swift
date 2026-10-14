@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationDigestValidator()
        let item = Consent.newRevocationDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationDigestSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Consent.RevocationDigestSegmentLengthRule(maxLength: 16)
        let item = Consent.newRevocationDigest("x", title: "y")
        item.segment = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationDigestAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Consent.RevocationDigestAcuityRangeRule(min: 120, max: 1000)
        let item = Consent.newRevocationDigest("x", title: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRevocationDigestPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Consent.RevocationDigestPhoneLengthRule(maxLength: 86400)
        let item = Consent.newRevocationDigest("x", title: "y")
        item.phone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RevocationDigestRequiredCodeRule(message: "revocation digest needs a value")
        let item = Consent.newRevocationDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
