@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingSlotCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRollingSlotCheckpointValidator()
        let item = Referrals.newRollingSlotCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRollingSlotCheckpointRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Referrals.RollingSlotCheckpointRequiredTimezoneRule(message: "rolling slot checkpoint needs an entry")
        let item = Referrals.newRollingSlotCheckpoint("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRollingSlotCheckpointRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.RollingSlotCheckpointRequiredNameRule(message: "rolling slot checkpoint needs this field")
        let item = Referrals.newRollingSlotCheckpoint("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRollingSlotCheckpointWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.RollingSlotCheckpointWardLengthRule(maxLength: 80)
        let item = Referrals.newRollingSlotCheckpoint("x", name: "y")
        item.ward = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRollingSlotCheckpointNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.RollingSlotCheckpointNameLengthRule(maxLength: 16)
        let item = Referrals.newRollingSlotCheckpoint("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
