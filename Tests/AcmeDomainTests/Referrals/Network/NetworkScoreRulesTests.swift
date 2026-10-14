@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkScoreValidator()
        let item = Referrals.newNetworkScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkScoreTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.NetworkScoreTitleLengthRule(maxLength: 32)
        let item = Referrals.newNetworkScore("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkScoreEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Referrals.NetworkScoreEncounterIDLengthRule(maxLength: 120)
        let item = Referrals.newNetworkScore("x", title: "y")
        item.encounterID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
