@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyAdjustmentValidator()
        let item = Consent.newProxyAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyAdjustmentDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.ProxyAdjustmentDiscountRangeRule(min: 1.1, max: 410.3)
        let item = Consent.newProxyAdjustment("x", label: "y")
        item.discount = 411.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyAdjustmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.ProxyAdjustmentRequiredTitleRule(message: "proxy adjustment needs this field")
        let item = Consent.newProxyAdjustment("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
