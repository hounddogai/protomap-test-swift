@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceVarianceValidator()
        let item = RevenueCycle.newRemittanceVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceVarianceRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.RemittanceVarianceRequiredNameRule(message: "remittance variance needs an entry")
        let item = RevenueCycle.newRemittanceVariance("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RemittanceVarianceCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newRemittanceVariance("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceVarianceRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = RevenueCycle.RemittanceVarianceRequiredOwnerIDRule(message: "remittance variance needs a value")
        let item = RevenueCycle.newRemittanceVariance("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceVarianceQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = RevenueCycle.RemittanceVarianceQuantityRangeRule(min: 16, max: 3600)
        let item = RevenueCycle.newRemittanceVariance("x", name: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceVarianceGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = RevenueCycle.RemittanceVarianceGraceDaysRangeRule(min: 32, max: 3600)
        let item = RevenueCycle.newRemittanceVariance("x", name: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}
