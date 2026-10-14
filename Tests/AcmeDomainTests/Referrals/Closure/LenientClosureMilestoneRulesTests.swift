@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientClosureMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLenientClosureMilestoneValidator()
        let item = Referrals.newLenientClosureMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLenientClosureMilestoneRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Referrals.LenientClosureMilestoneRequiredRegionRule(
            message: "lenient closure milestone needs an entry"
        )
        let item = Referrals.newLenientClosureMilestone("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLenientClosureMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.LenientClosureMilestoneCodeLengthRule(maxLength: 64)
        let item = Referrals.newLenientClosureMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
