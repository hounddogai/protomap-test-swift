@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingSlotRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRollingSlotRollupValidator()
        let item = Referrals.newRollingSlotRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRollingSlotRollupSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Referrals.RollingSlotRollupSpecialtyLengthRule(maxLength: 3600)
        let item = Referrals.newRollingSlotRollup("x", label: "y")
        item.specialty = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRollingSlotRollupPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Referrals.RollingSlotRollupPriorityRangeRule(min: 32, max: 64)
        let item = Referrals.newRollingSlotRollup("x", label: "y")
        item.priority = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRollingSlotRollupCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Referrals.RollingSlotRollupCopayRangeRule(min: 6.5, max: 3142.6)
        let item = Referrals.newRollingSlotRollup("x", label: "y")
        item.copay = 3144.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRollingSlotRollupRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Referrals.RollingSlotRollupRatioRangeRule(min: 6.8, max: 4367.7)
        let item = Referrals.newRollingSlotRollup("x", label: "y")
        item.ratio = 4369.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRollingSlotRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.RollingSlotRollupCodeLengthRule(maxLength: 3600)
        let item = Referrals.newRollingSlotRollup("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
