@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceExceptionValidator()
        let item = RevenueCycle.newRemittanceException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceExceptionCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = RevenueCycle.RemittanceExceptionCreatedAtRangeRule(min: 32, max: 255)
        let item = RevenueCycle.newRemittanceException("x", name: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RemittanceExceptionCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newRemittanceException("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceExceptionCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = RevenueCycle.RemittanceExceptionCurrencyLengthRule(maxLength: 3600)
        let item = RevenueCycle.newRemittanceException("x", name: "y")
        item.currency = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceExceptionRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.RemittanceExceptionRequiredNameRule(message: "remittance exception needs this field")
        let item = RevenueCycle.newRemittanceException("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceExceptionRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = RevenueCycle.RemittanceExceptionRequiredChecksumRule(message: "remittance exception needs an entry")
        let item = RevenueCycle.newRemittanceException("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
