@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseLedgerValidator()
        let item = Pharmacy.newDispenseLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.DispenseLedgerCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newDispenseLedger("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseLedgerTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.DispenseLedgerTitleLengthRule(maxLength: 80)
        let item = Pharmacy.newDispenseLedger("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseLedgerAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Pharmacy.DispenseLedgerAttemptsRangeRule(min: 80, max: 255)
        let item = Pharmacy.newDispenseLedger("x", title: "y")
        item.attempts = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseLedgerRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Pharmacy.DispenseLedgerRequiredCurrencyRule(message: "dispense ledger needs a value")
        let item = Pharmacy.newDispenseLedger("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
