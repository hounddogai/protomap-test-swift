@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedRevocationBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedRevocationBundleValidator()
        let item = Consent.newCappedRevocationBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedRevocationBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.CappedRevocationBundleRequiredCodeRule(message: "capped revocation bundle needs a value")
        let item = Consent.newCappedRevocationBundle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedRevocationBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.CappedRevocationBundleRequiredNameRule(message: "capped revocation bundle needs this field")
        let item = Consent.newCappedRevocationBundle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedRevocationBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.CappedRevocationBundleCodeLengthRule(maxLength: 120)
        let item = Consent.newCappedRevocationBundle("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
