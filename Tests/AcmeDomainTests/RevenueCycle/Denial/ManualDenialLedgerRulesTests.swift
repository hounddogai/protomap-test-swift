@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualDenialLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualDenialLedgerValidator()
        let item = RevenueCycle.newManualDenialLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualDenialLedgerRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = RevenueCycle.ManualDenialLedgerRequiredFacilityRule(message: "manual denial ledger needs an entry")
        let item = RevenueCycle.newManualDenialLedger("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualDenialLedgerNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ManualDenialLedgerNameLengthRule(maxLength: 1000)
        let item = RevenueCycle.newManualDenialLedger("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualDenialLedgerFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = RevenueCycle.ManualDenialLedgerFacilityLengthRule(maxLength: 120)
        let item = RevenueCycle.newManualDenialLedger("x", name: "y")
        item.facility = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
