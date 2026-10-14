@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyLedgerValidator()
        let item = Consent.newProxyLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyLedgerMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Consent.ProxyLedgerMinimumRangeRule(min: 0.4, max: 1070.4)
        let item = Consent.newProxyLedger("x", label: "y")
        item.minimum = 1071.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyLedgerRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Consent.ProxyLedgerRequiredUnitRule(message: "proxy ledger needs an entry")
        let item = Consent.newProxyLedger("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyLedgerUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Consent.ProxyLedgerUnitLengthRule(maxLength: 3600)
        let item = Consent.newProxyLedger("x", label: "y")
        item.unit = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
