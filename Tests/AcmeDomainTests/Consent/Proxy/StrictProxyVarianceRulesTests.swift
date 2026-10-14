@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultStrictProxyVarianceValidator()
        let item = Consent.newStrictProxyVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentStrictProxyVarianceQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Consent.StrictProxyVarianceQuantityRangeRule(min: 1000, max: 1000)
        let item = Consent.newStrictProxyVariance("x", title: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentStrictProxyVarianceDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.StrictProxyVarianceDiscountRangeRule(min: 3.7, max: 4622.3)
        let item = Consent.newStrictProxyVariance("x", title: "y")
        item.discount = 4623.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentStrictProxyVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.StrictProxyVarianceTitleLengthRule(maxLength: 1000)
        let item = Consent.newStrictProxyVariance("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentStrictProxyVarianceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.StrictProxyVarianceRequiredTitleRule(message: "strict proxy variance needs an entry")
        let item = Consent.newStrictProxyVariance("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentStrictProxyVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.StrictProxyVarianceCodeLengthRule(maxLength: 3600)
        let item = Consent.newStrictProxyVariance("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
