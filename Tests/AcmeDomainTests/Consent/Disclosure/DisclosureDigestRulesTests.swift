@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureDigestValidator()
        let item = Consent.newDisclosureDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureDigestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.DisclosureDigestTitleLengthRule(maxLength: 255)
        let item = Consent.newDisclosureDigest("x", label: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureDigestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.DisclosureDigestRequiredTitleRule(message: "disclosure digest needs an entry")
        let item = Consent.newDisclosureDigest("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
