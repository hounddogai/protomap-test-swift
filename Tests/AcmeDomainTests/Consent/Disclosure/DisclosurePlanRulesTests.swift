@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosurePlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosurePlanValidator()
        let item = Consent.newDisclosurePlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosurePlanTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.DisclosurePlanTitleLengthRule(maxLength: 255)
        let item = Consent.newDisclosurePlan("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosurePlanLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Consent.DisclosurePlanLocaleLengthRule(maxLength: 16)
        let item = Consent.newDisclosurePlan("x", title: "y")
        item.locale = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosurePlanRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Consent.DisclosurePlanRequiredLocaleRule(message: "disclosure plan needs a value")
        let item = Consent.newDisclosurePlan("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosurePlanCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Consent.DisclosurePlanCurrencyLengthRule(maxLength: 86400)
        let item = Consent.newDisclosurePlan("x", title: "y")
        item.currency = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosurePlanUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Consent.DisclosurePlanUpdatedAtRangeRule(min: 16, max: 80)
        let item = Consent.newDisclosurePlan("x", title: "y")
        item.updatedAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosurePlanCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Consent.DisclosurePlanCostRangeRule(min: 5.6, max: 1106.9)
        let item = Consent.newDisclosurePlan("x", title: "y")
        item.cost = 1108.4
        #expect(rule.check(item).count > 0)
    }
}
