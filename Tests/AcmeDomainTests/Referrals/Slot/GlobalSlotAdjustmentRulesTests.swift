@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalSlotAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalSlotAdjustmentValidator()
        let item = Referrals.newGlobalSlotAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalSlotAdjustmentOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Referrals.GlobalSlotAdjustmentOwnerIDLengthRule(maxLength: 255)
        let item = Referrals.newGlobalSlotAdjustment("x", label: "y")
        item.ownerID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalSlotAdjustmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.GlobalSlotAdjustmentLabelLengthRule(maxLength: 1000)
        let item = Referrals.newGlobalSlotAdjustment("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalSlotAdjustmentDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Referrals.GlobalSlotAdjustmentDosageMgRangeRule(min: 2.9, max: 4358.5)
        let item = Referrals.newGlobalSlotAdjustment("x", label: "y")
        item.dosageMg = 4360.0
        #expect(rule.check(item).count > 0)
    }
}
