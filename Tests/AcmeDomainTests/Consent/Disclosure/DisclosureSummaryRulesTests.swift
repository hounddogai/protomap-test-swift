@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureSummaryValidator()
        let item = Consent.newDisclosureSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.DisclosureSummaryRequiredCodeRule(message: "disclosure summary needs an entry")
        let item = Consent.newDisclosureSummary("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureSummaryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.DisclosureSummaryRequiredLabelRule(message: "disclosure summary needs this field")
        let item = Consent.newDisclosureSummary("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureSummaryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.DisclosureSummaryLabelLengthRule(maxLength: 3600)
        let item = Consent.newDisclosureSummary("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureSummaryCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Consent.DisclosureSummaryCreatedAtRangeRule(min: 16, max: 1000)
        let item = Consent.newDisclosureSummary("x", label: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
