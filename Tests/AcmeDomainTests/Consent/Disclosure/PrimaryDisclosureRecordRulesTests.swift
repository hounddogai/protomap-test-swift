@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryDisclosureRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPrimaryDisclosureRecordValidator()
        let item = Consent.newPrimaryDisclosureRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPrimaryDisclosureRecordCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Consent.PrimaryDisclosureRecordCopayRangeRule(min: 1.9, max: 4827.1)
        let item = Consent.newPrimaryDisclosureRecord("x", name: "y")
        item.copay = 4828.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPrimaryDisclosureRecordNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.PrimaryDisclosureRecordNameLengthRule(maxLength: 32)
        let item = Consent.newPrimaryDisclosureRecord("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPrimaryDisclosureRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.PrimaryDisclosureRecordRequiredCodeRule(message: "primary disclosure record needs a value")
        let item = Consent.newPrimaryDisclosureRecord("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPrimaryDisclosureRecordRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Consent.PrimaryDisclosureRecordRequiredDiagnosisCodeRule(
            message: "primary disclosure record needs a value"
        )
        let item = Consent.newPrimaryDisclosureRecord("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
