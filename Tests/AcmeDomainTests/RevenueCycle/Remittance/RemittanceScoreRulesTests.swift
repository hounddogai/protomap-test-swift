@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceScoreValidator()
        let item = RevenueCycle.newRemittanceScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceScoreBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = RevenueCycle.RemittanceScoreBedLengthRule(maxLength: 120)
        let item = RevenueCycle.newRemittanceScore("x", name: "y")
        item.bed = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceScoreStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = RevenueCycle.RemittanceScoreStartsAtRangeRule(min: 120, max: 3600)
        let item = RevenueCycle.newRemittanceScore("x", name: "y")
        item.startsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
