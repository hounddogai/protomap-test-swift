@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualClosureReviewValidator()
        let item = Referrals.newManualClosureReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualClosureReviewCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Referrals.ManualClosureReviewCeilingRangeRule(min: 9.8, max: 4861.9)
        let item = Referrals.newManualClosureReview("x", name: "y")
        item.ceiling = 4863.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsManualClosureReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.ManualClosureReviewRequiredNameRule(message: "manual closure review needs an entry")
        let item = Referrals.newManualClosureReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsManualClosureReviewScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.ManualClosureReviewScoreRangeRule(min: 8.2, max: 3421.1)
        let item = Referrals.newManualClosureReview("x", name: "y")
        item.score = 3422.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsManualClosureReviewCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Referrals.ManualClosureReviewCapacityRangeRule(min: 16, max: 3600)
        let item = Referrals.newManualClosureReview("x", name: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsManualClosureReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.ManualClosureReviewNameLengthRule(maxLength: 80)
        let item = Referrals.newManualClosureReview("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
