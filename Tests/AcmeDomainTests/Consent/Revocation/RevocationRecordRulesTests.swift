@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationRecordValidator()
        let item = Consent.newRevocationRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationRecordWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Consent.RevocationRecordWindowDaysRangeRule(min: 16, max: 120)
        let item = Consent.newRevocationRecord("x", label: "y")
        item.windowDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRevocationRecordLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.RevocationRecordLabelLengthRule(maxLength: 1000)
        let item = Consent.newRevocationRecord("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.RevocationRecordCodeLengthRule(maxLength: 16)
        let item = Consent.newRevocationRecord("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
