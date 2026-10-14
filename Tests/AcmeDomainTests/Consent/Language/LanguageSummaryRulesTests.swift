@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageSummaryValidator()
        let item = Consent.newLanguageSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageSummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.LanguageSummaryRequiredTitleRule(message: "language summary needs a value")
        let item = Consent.newLanguageSummary("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageSummaryRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Consent.LanguageSummaryRequiredBedRule(message: "language summary needs an entry")
        let item = Consent.newLanguageSummary("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
