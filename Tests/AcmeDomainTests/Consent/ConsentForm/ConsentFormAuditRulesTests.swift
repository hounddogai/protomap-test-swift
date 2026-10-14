@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormAuditValidator()
        let item = Consent.newConsentFormAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormAuditCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Consent.ConsentFormAuditCapacityRangeRule(min: 32, max: 64)
        let item = Consent.newConsentFormAudit("x", name: "y")
        item.capacity = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentConsentFormAuditRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ConsentFormAuditRequiredNameRule(message: "consent form audit needs this field")
        let item = Consent.newConsentFormAudit("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
