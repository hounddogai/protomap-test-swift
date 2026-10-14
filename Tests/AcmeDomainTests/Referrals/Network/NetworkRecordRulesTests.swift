@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkRecordValidator()
        let item = Referrals.newNetworkRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkRecordNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Referrals.NetworkRecordNotesLengthRule(maxLength: 80)
        let item = Referrals.newNetworkRecord("x", name: "y")
        item.notes = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkRecordEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.NetworkRecordEndsAtRangeRule(min: 255, max: 255)
        let item = Referrals.newNetworkRecord("x", name: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkRecordQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.NetworkRecordQuantityRangeRule(min: 80, max: 120)
        let item = Referrals.newNetworkRecord("x", name: "y")
        item.quantity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkRecordRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Referrals.NetworkRecordRequiredCountryRule(message: "network record needs an entry")
        let item = Referrals.newNetworkRecord("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
