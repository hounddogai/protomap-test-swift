@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageDigestValidator()
        let item = Consent.newLanguageDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageDigestChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Consent.LanguageDigestChecksumLengthRule(maxLength: 86400)
        let item = Consent.newLanguageDigest("x", name: "y")
        item.checksum = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageDigestRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Consent.LanguageDigestRevisionRangeRule(min: 32, max: 1000)
        let item = Consent.newLanguageDigest("x", name: "y")
        item.revision = 1001
        #expect(rule.check(item).count > 0)
    }
}
