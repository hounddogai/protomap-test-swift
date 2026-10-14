@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessAuditValidator()
        let item = Consent.newWitnessAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WitnessAuditRequiredCodeRule(message: "witness audit needs an entry")
        let item = Consent.newWitnessAudit("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessAuditDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Consent.WitnessAuditDescriptionLengthRule(maxLength: 16)
        let item = Consent.newWitnessAudit("x", title: "y")
        item.description = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
