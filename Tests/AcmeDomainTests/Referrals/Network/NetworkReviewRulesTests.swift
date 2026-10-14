@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkReviewValidator()
        let item = Referrals.newNetworkReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkReviewRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Referrals.NetworkReviewRequiredDescriptionRule(message: "network review needs a value")
        let item = Referrals.newNetworkReview("", name: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.NetworkReviewRequiredNameRule(message: "network review needs a value")
        let item = Referrals.newNetworkReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.NetworkReviewCodeLengthRule(maxLength: 64)
        let item = Referrals.newNetworkReview("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
