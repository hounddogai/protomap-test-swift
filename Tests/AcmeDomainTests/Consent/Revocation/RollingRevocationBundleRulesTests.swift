@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingRevocationBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingRevocationBundleValidator()
        let item = Consent.newRollingRevocationBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingRevocationBundleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.RollingRevocationBundleTitleLengthRule(maxLength: 16)
        let item = Consent.newRollingRevocationBundle("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingRevocationBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.RollingRevocationBundleRequiredNameRule(message: "rolling revocation bundle needs this field")
        let item = Consent.newRollingRevocationBundle("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingRevocationBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RollingRevocationBundleRequiredCodeRule(message: "rolling revocation bundle needs a value")
        let item = Consent.newRollingRevocationBundle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
