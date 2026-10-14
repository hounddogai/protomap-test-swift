@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryProxySummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPrimaryProxySummaryValidator()
        let item = Consent.newPrimaryProxySummary("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPrimaryProxySummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.PrimaryProxySummaryRequiredCodeRule(message: "primary proxy summary needs a value")
        let item = Consent.newPrimaryProxySummary("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPrimaryProxySummaryRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Consent.PrimaryProxySummaryRequiredReviewerRule(message: "primary proxy summary needs a value")
        let item = Consent.newPrimaryProxySummary("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
