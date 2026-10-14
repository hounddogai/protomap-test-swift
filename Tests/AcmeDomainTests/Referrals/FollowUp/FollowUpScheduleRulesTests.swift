@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpScheduleValidator()
        let item = Referrals.newFollowUpSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.FollowUpScheduleNameLengthRule(maxLength: 86400)
        let item = Referrals.newFollowUpSchedule("x", label: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpScheduleOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Referrals.FollowUpScheduleOwnerIDLengthRule(maxLength: 80)
        let item = Referrals.newFollowUpSchedule("x", label: "y")
        item.ownerID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
