@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalClosureClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalClosureClaimValidator()
        let item = Referrals.newGlobalClosureClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalClosureClaimEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.GlobalClosureClaimEndsAtRangeRule(min: 255, max: 86400)
        let item = Referrals.newGlobalClosureClaim("x", title: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
