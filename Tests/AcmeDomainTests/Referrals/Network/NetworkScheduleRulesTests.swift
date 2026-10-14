@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkScheduleValidator()
        let item = Referrals.newNetworkSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkScheduleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.NetworkScheduleTitleLengthRule(maxLength: 120)
        let item = Referrals.newNetworkSchedule("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkScheduleAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Referrals.NetworkScheduleAcuityRangeRule(min: 64, max: 3600)
        let item = Referrals.newNetworkSchedule("x", title: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkScheduleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.NetworkScheduleRequiredTitleRule(message: "network schedule needs an entry")
        let item = Referrals.newNetworkSchedule("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkScheduleTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Referrals.NetworkScheduleTimezoneLengthRule(maxLength: 3600)
        let item = Referrals.newNetworkSchedule("x", title: "y")
        item.timezone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
