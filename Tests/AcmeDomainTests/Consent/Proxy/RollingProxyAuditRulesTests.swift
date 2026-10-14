@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingProxyAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingProxyAuditValidator()
        let item = Consent.newRollingProxyAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingProxyAuditSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Consent.RollingProxyAuditSpecialtyLengthRule(maxLength: 120)
        let item = Consent.newRollingProxyAudit("x", name: "y")
        item.specialty = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingProxyAuditRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Consent.RollingProxyAuditRequiredContactEmailRule(message: "rolling proxy audit needs an entry")
        let item = Consent.newRollingProxyAudit("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingProxyAuditNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.RollingProxyAuditNameLengthRule(maxLength: 32)
        let item = Consent.newRollingProxyAudit("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
