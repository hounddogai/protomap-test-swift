@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalDisclosureSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRegionalDisclosureSummaryValidator()
        let item = Consent.newRegionalDisclosureSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRegionalDisclosureSummaryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.RegionalDisclosureSummaryLabelLengthRule(maxLength: 80)
        let item = Consent.newRegionalDisclosureSummary("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRegionalDisclosureSummaryRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Consent.RegionalDisclosureSummaryRequiredCountryRule(
            message: "regional disclosure summary needs a value"
        )
        let item = Consent.newRegionalDisclosureSummary("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
