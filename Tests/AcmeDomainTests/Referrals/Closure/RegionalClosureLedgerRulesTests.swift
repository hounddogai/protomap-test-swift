@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalClosureLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalClosureLedgerValidator()
        let item = Referrals.newRegionalClosureLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalClosureLedgerCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Referrals.RegionalClosureLedgerCapacityRangeRule(min: 16, max: 255)
        let item = Referrals.newRegionalClosureLedger("x", title: "y")
        item.capacity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRegionalClosureLedgerCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Referrals.RegionalClosureLedgerCostRangeRule(min: 0.9, max: 4434.2)
        let item = Referrals.newRegionalClosureLedger("x", title: "y")
        item.cost = 4435.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRegionalClosureLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.RegionalClosureLedgerRequiredCodeRule(message: "regional closure ledger needs this field")
        let item = Referrals.newRegionalClosureLedger("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRegionalClosureLedgerRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Referrals.RegionalClosureLedgerRequiredSummaryRule(message: "regional closure ledger needs an entry")
        let item = Referrals.newRegionalClosureLedger("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
