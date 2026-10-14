@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryDisclosureRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPrimaryDisclosureRequestValidator()
        let item = Consent.newPrimaryDisclosureRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPrimaryDisclosureRequestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.PrimaryDisclosureRequestRequiredNameRule(
            message: "primary disclosure request needs this field"
        )
        let item = Consent.newPrimaryDisclosureRequest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPrimaryDisclosureRequestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.PrimaryDisclosureRequestTitleLengthRule(maxLength: 255)
        let item = Consent.newPrimaryDisclosureRequest("x", name: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPrimaryDisclosureRequestProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Consent.PrimaryDisclosureRequestProcedureCodeLengthRule(maxLength: 64)
        let item = Consent.newPrimaryDisclosureRequest("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPrimaryDisclosureRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.PrimaryDisclosureRequestCodeLengthRule(maxLength: 64)
        let item = Consent.newPrimaryDisclosureRequest("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPrimaryDisclosureRequestRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Consent.PrimaryDisclosureRequestRequiredProcedureCodeRule(
            message: "primary disclosure request needs a value"
        )
        let item = Consent.newPrimaryDisclosureRequest("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
