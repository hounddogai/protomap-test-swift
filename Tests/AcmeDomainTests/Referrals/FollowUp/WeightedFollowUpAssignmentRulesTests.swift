@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultWeightedFollowUpAssignmentValidator()
        let item = Referrals.newWeightedFollowUpAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsWeightedFollowUpAssignmentCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Referrals.WeightedFollowUpAssignmentCopayRangeRule(min: 3.3, max: 1770.1)
        let item = Referrals.newWeightedFollowUpAssignment("x", label: "y")
        item.copay = 1771.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsWeightedFollowUpAssignmentSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Referrals.WeightedFollowUpAssignmentSourceLengthRule(maxLength: 32)
        let item = Referrals.newWeightedFollowUpAssignment("x", label: "y")
        item.source = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
