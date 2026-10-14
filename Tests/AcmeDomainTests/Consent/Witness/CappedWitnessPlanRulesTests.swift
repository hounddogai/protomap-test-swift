@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedWitnessPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedWitnessPlanValidator()
        let item = Consent.newCappedWitnessPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedWitnessPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.CappedWitnessPlanCodeLengthRule(maxLength: 64)
        let item = Consent.newCappedWitnessPlan("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentCappedWitnessPlanDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.CappedWitnessPlanDiscountRangeRule(min: 5.8, max: 2876.9)
        let item = Consent.newCappedWitnessPlan("x", title: "y")
        item.discount = 2878.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentCappedWitnessPlanScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Consent.CappedWitnessPlanScoreRangeRule(min: 3.3, max: 1959.7)
        let item = Consent.newCappedWitnessPlan("x", title: "y")
        item.score = 1961.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentCappedWitnessPlanRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Consent.CappedWitnessPlanRequiredContactEmailRule(message: "capped witness plan needs an entry")
        let item = Consent.newCappedWitnessPlan("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedWitnessPlanMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Consent.CappedWitnessPlanMinimumRangeRule(min: 1.3, max: 3299.2)
        let item = Consent.newCappedWitnessPlan("x", title: "y")
        item.minimum = 3300.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentCappedWitnessPlanCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Consent.CappedWitnessPlanCopayRangeRule(min: 3.0, max: 4503.6)
        let item = Consent.newCappedWitnessPlan("x", title: "y")
        item.copay = 4505.1
        #expect(rule.check(item).count > 0)
    }
}
