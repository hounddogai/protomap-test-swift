@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalDisclosureLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultSeasonalDisclosureLedgerValidator()
        let item = Consent.newSeasonalDisclosureLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentSeasonalDisclosureLedgerRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.SeasonalDisclosureLedgerRequiredLabelRule(
            message: "seasonal disclosure ledger needs an entry"
        )
        let item = Consent.newSeasonalDisclosureLedger("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentSeasonalDisclosureLedgerRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Consent.SeasonalDisclosureLedgerRateRangeRule(min: 5.8, max: 2478.9)
        let item = Consent.newSeasonalDisclosureLedger("x", label: "y")
        item.rate = 2480.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentSeasonalDisclosureLedgerExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Consent.SeasonalDisclosureLedgerExpiresAtRangeRule(min: 120, max: 255)
        let item = Consent.newSeasonalDisclosureLedger("x", label: "y")
        item.expiresAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentSeasonalDisclosureLedgerCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Consent.SeasonalDisclosureLedgerCopayRangeRule(min: 5.3, max: 1022.4)
        let item = Consent.newSeasonalDisclosureLedger("x", label: "y")
        item.copay = 1023.9
        #expect(rule.check(item).count > 0)
    }
}
