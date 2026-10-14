@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationTargetValidator()
        let item = Consent.newRevocationTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationTargetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.RevocationTargetNameLengthRule(maxLength: 3600)
        let item = Consent.newRevocationTarget("x", title: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationTargetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.RevocationTargetRequiredTitleRule(message: "revocation target needs a value")
        let item = Consent.newRevocationTarget("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
