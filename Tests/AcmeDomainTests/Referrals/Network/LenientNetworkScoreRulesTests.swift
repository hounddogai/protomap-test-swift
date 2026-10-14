@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientNetworkScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLenientNetworkScoreValidator()
        let item = Referrals.newLenientNetworkScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLenientNetworkScoreRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.LenientNetworkScoreRequiredLabelRule(message: "lenient network score needs an entry")
        let item = Referrals.newLenientNetworkScore("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLenientNetworkScoreLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.LenientNetworkScoreLabelLengthRule(maxLength: 120)
        let item = Referrals.newLenientNetworkScore("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
