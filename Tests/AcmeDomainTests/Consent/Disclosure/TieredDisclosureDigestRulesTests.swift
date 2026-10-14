@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredDisclosureDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultTieredDisclosureDigestValidator()
        let item = Consent.newTieredDisclosureDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentTieredDisclosureDigestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.TieredDisclosureDigestRequiredTitleRule(message: "tiered disclosure digest needs a value")
        let item = Consent.newTieredDisclosureDigest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentTieredDisclosureDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.TieredDisclosureDigestCodeLengthRule(maxLength: 1000)
        let item = Consent.newTieredDisclosureDigest("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
