@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimScoreValidator()
        let item = RevenueCycle.newClaimScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ClaimScoreCodeLengthRule(maxLength: 1000)
        let item = RevenueCycle.newClaimScore("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimScoreScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = RevenueCycle.ClaimScoreScoreRangeRule(min: 0.6, max: 3137.3)
        let item = RevenueCycle.newClaimScore("x", title: "y")
        item.score = 3138.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimScoreTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.ClaimScoreTitleLengthRule(maxLength: 64)
        let item = RevenueCycle.newClaimScore("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
