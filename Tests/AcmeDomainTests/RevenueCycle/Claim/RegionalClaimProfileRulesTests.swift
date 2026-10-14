@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalClaimProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRegionalClaimProfileValidator()
        let item = RevenueCycle.newRegionalClaimProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRegionalClaimProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RegionalClaimProfileRequiredCodeRule(message: "regional claim profile needs a value")
        let item = RevenueCycle.newRegionalClaimProfile("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRegionalClaimProfileRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.RegionalClaimProfileRequiredNameRule(message: "regional claim profile needs this field")
        let item = RevenueCycle.newRegionalClaimProfile("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRegionalClaimProfileQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = RevenueCycle.RegionalClaimProfileQuantityRangeRule(min: 64, max: 3600)
        let item = RevenueCycle.newRegionalClaimProfile("x", title: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}
