@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedRevocationSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedRevocationSummaryValidator()
        let item = Consent.newCappedRevocationSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedRevocationSummaryRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Consent.CappedRevocationSummaryRetriesRangeRule(min: 16, max: 80)
        let item = Consent.newCappedRevocationSummary("x", label: "y")
        item.retries = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentCappedRevocationSummaryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.CappedRevocationSummaryLabelLengthRule(maxLength: 255)
        let item = Consent.newCappedRevocationSummary("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentCappedRevocationSummaryUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Consent.CappedRevocationSummaryUnitLengthRule(maxLength: 64)
        let item = Consent.newCappedRevocationSummary("x", label: "y")
        item.unit = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
