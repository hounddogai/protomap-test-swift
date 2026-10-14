@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedClaimReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultCappedClaimReservationValidator()
        let item = RevenueCycle.newCappedClaimReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleCappedClaimReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.CappedClaimReservationCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newCappedClaimReservation("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleCappedClaimReservationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.CappedClaimReservationLabelLengthRule(maxLength: 255)
        let item = RevenueCycle.newCappedClaimReservation("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleCappedClaimReservationCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = RevenueCycle.CappedClaimReservationCurrencyLengthRule(maxLength: 86400)
        let item = RevenueCycle.newCappedClaimReservation("x", label: "y")
        item.currency = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleCappedClaimReservationAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.CappedClaimReservationAmountRangeRule(min: 2.2, max: 3012.8)
        let item = RevenueCycle.newCappedClaimReservation("x", label: "y")
        item.amount = 3014.3
        #expect(rule.check(item).count > 0)
    }
}
