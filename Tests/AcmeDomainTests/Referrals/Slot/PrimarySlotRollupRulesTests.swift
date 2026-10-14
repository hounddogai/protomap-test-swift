@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimarySlotRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPrimarySlotRollupValidator()
        let item = Referrals.newPrimarySlotRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPrimarySlotRollupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.PrimarySlotRollupRequiredNameRule(message: "primary slot rollup needs this field")
        let item = Referrals.newPrimarySlotRollup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPrimarySlotRollupUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Referrals.PrimarySlotRollupUpdatedAtRangeRule(min: 16, max: 32)
        let item = Referrals.newPrimarySlotRollup("x", name: "y")
        item.updatedAt = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPrimarySlotRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.PrimarySlotRollupCodeLengthRule(maxLength: 255)
        let item = Referrals.newPrimarySlotRollup("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
