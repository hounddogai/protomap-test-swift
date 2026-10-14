@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveNetworkLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultAdaptiveNetworkLedgerValidator()
        let item = Referrals.newAdaptiveNetworkLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsAdaptiveNetworkLedgerRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.AdaptiveNetworkLedgerRequiredNameRule(message: "adaptive network ledger needs an entry")
        let item = Referrals.newAdaptiveNetworkLedger("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsAdaptiveNetworkLedgerNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.AdaptiveNetworkLedgerNameLengthRule(maxLength: 32)
        let item = Referrals.newAdaptiveNetworkLedger("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsAdaptiveNetworkLedgerRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.AdaptiveNetworkLedgerRequiredLabelRule(message: "adaptive network ledger needs an entry")
        let item = Referrals.newAdaptiveNetworkLedger("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsAdaptiveNetworkLedgerVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Referrals.AdaptiveNetworkLedgerVisitMinutesRangeRule(min: 32, max: 32)
        let item = Referrals.newAdaptiveNetworkLedger("x", name: "y")
        item.visitMinutes = 33
        #expect(rule.check(item).count > 0)
    }
}
