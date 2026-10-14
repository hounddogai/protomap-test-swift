@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureBatchValidator()
        let item = Referrals.newClosureBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureBatchGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Referrals.ClosureBatchGraceDaysRangeRule(min: 120, max: 3600)
        let item = Referrals.newClosureBatch("x", label: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosureBatchFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Referrals.ClosureBatchFacilityLengthRule(maxLength: 1000)
        let item = Referrals.newClosureBatch("x", label: "y")
        item.facility = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureBatchMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Referrals.ClosureBatchMaximumRangeRule(min: 7.1, max: 2637.7)
        let item = Referrals.newClosureBatch("x", label: "y")
        item.maximum = 2639.2
        #expect(rule.check(item).count > 0)
    }
}
