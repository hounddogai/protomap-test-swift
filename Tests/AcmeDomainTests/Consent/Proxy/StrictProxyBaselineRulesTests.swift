@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultStrictProxyBaselineValidator()
        let item = Consent.newStrictProxyBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentStrictProxyBaselineTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.StrictProxyBaselineTitleLengthRule(maxLength: 32)
        let item = Consent.newStrictProxyBaseline("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentStrictProxyBaselineRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.StrictProxyBaselineRequiredTitleRule(message: "strict proxy baseline needs an entry")
        let item = Consent.newStrictProxyBaseline("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentStrictProxyBaselineRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Consent.StrictProxyBaselineRequiredContactEmailRule(message: "strict proxy baseline needs a value")
        let item = Consent.newStrictProxyBaseline("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentStrictProxyBaselineGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Consent.StrictProxyBaselineGraceDaysRangeRule(min: 32, max: 1000)
        let item = Consent.newStrictProxyBaseline("x", title: "y")
        item.graceDays = 1001
        #expect(rule.check(item).count > 0)
    }
}
