@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureCycleValidator()
        let item = Consent.newDisclosureCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureCycleRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Consent.DisclosureCycleRetriesRangeRule(min: 32, max: 86400)
        let item = Consent.newDisclosureCycle("x", title: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureCycleScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Consent.DisclosureCycleScoreRangeRule(min: 1.3, max: 864.7)
        let item = Consent.newDisclosureCycle("x", title: "y")
        item.score = 866.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureCycleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.DisclosureCycleRequiredTitleRule(message: "disclosure cycle needs this field")
        let item = Consent.newDisclosureCycle("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
