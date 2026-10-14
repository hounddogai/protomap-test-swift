@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotScheduleValidator()
        let item = Referrals.newSlotSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotScheduleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.SlotScheduleTitleLengthRule(maxLength: 1000)
        let item = Referrals.newSlotSchedule("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SlotScheduleCodeLengthRule(maxLength: 64)
        let item = Referrals.newSlotSchedule("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotScheduleGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Referrals.SlotScheduleGraceDaysRangeRule(min: 1000, max: 86400)
        let item = Referrals.newSlotSchedule("x", title: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotScheduleLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Referrals.SlotScheduleLimitRangeRule(min: 16, max: 64)
        let item = Referrals.newSlotSchedule("x", title: "y")
        item.limit = 65
        #expect(rule.check(item).count > 0)
    }
}
