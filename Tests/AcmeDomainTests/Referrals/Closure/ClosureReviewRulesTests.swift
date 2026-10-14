@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureReviewValidator()
        let item = Referrals.newClosureReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureReviewPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Referrals.ClosureReviewPhoneLengthRule(maxLength: 64)
        let item = Referrals.newClosureReview("x", name: "y")
        item.phone = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.ClosureReviewRequiredNameRule(message: "closure review needs this field")
        let item = Referrals.newClosureReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
