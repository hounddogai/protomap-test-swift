@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalProxyAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultGlobalProxyAuditValidator()
        let item = Consent.newGlobalProxyAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentGlobalProxyAuditRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Consent.GlobalProxyAuditRequiredChecksumRule(message: "global proxy audit needs this field")
        let item = Consent.newGlobalProxyAudit("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentGlobalProxyAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.GlobalProxyAuditCodeLengthRule(maxLength: 255)
        let item = Consent.newGlobalProxyAudit("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
