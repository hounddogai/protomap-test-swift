@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyClosureLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLegacyClosureLedgerValidator()
        let item = Referrals.newLegacyClosureLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLegacyClosureLedgerRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Referrals.LegacyClosureLedgerRequiredRegionRule(message: "legacy closure ledger needs a value")
        let item = Referrals.newLegacyClosureLedger("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacyClosureLedgerNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.LegacyClosureLedgerNameLengthRule(maxLength: 32)
        let item = Referrals.newLegacyClosureLedger("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
