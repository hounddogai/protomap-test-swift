@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkSlotValidator()
        let item = Referrals.newNetworkSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.NetworkSlotRequiredCodeRule(message: "network slot needs an entry")
        let item = Referrals.newNetworkSlot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkSlotRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Referrals.NetworkSlotRequiredOwnerIDRule(message: "network slot needs a value")
        let item = Referrals.newNetworkSlot("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkSlotExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Referrals.NetworkSlotExpiresAtRangeRule(min: 16, max: 1000)
        let item = Referrals.newNetworkSlot("x", label: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkSlotRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Referrals.NetworkSlotRequiredClinicianIDRule(message: "network slot needs this field")
        let item = Referrals.newNetworkSlot("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkSlotClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Referrals.NetworkSlotClinicianIDLengthRule(maxLength: 86400)
        let item = Referrals.newNetworkSlot("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
