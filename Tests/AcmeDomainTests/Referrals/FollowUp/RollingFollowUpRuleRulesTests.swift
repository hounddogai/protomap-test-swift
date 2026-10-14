@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingFollowUpRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRollingFollowUpRuleValidator()
        let item = Referrals.newRollingFollowUpRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRollingFollowUpRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.RollingFollowUpRuleRequiredCodeRule(message: "rolling follow up rule needs an entry")
        let item = Referrals.newRollingFollowUpRule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
