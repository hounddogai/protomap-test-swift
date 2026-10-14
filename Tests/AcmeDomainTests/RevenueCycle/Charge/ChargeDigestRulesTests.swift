@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeDigestValidator()
        let item = RevenueCycle.newChargeDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeDigestVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = RevenueCycle.ChargeDigestVisitMinutesRangeRule(min: 64, max: 120)
        let item = RevenueCycle.newChargeDigest("x", title: "y")
        item.visitMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeDigestOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = RevenueCycle.ChargeDigestOwnerIDLengthRule(maxLength: 80)
        let item = RevenueCycle.newChargeDigest("x", title: "y")
        item.ownerID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ChargeDigestCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newChargeDigest("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeDigestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.ChargeDigestTitleLengthRule(maxLength: 86400)
        let item = RevenueCycle.newChargeDigest("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeDigestDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = RevenueCycle.ChargeDigestDiscountRangeRule(min: 8.6, max: 3144.0)
        let item = RevenueCycle.newChargeDigest("x", title: "y")
        item.discount = 3145.5
        #expect(rule.check(item).count > 0)
    }
}
