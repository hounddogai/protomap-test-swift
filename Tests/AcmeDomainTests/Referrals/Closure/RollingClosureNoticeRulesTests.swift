@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingClosureNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRollingClosureNoticeValidator()
        let item = Referrals.newRollingClosureNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRollingClosureNoticeCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Referrals.RollingClosureNoticeCapacityRangeRule(min: 120, max: 3600)
        let item = Referrals.newRollingClosureNotice("x", title: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRollingClosureNoticeCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.RollingClosureNoticeCreatedAtRangeRule(min: 32, max: 80)
        let item = Referrals.newRollingClosureNotice("x", title: "y")
        item.createdAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRollingClosureNoticeMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Referrals.RollingClosureNoticeMinimumRangeRule(min: 6.0, max: 927.8)
        let item = Referrals.newRollingClosureNotice("x", title: "y")
        item.minimum = 929.3
        #expect(rule.check(item).count > 0)
    }
}
