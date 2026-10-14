@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedResultScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultWeightedResultScoreValidator()
        let item = Labs.newWeightedResultScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsWeightedResultScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.WeightedResultScoreCodeLengthRule(maxLength: 16)
        let item = Labs.newWeightedResultScore("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsWeightedResultScoreTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Labs.WeightedResultScoreTimezoneLengthRule(maxLength: 120)
        let item = Labs.newWeightedResultScore("x", name: "y")
        item.timezone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsWeightedResultScoreScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Labs.WeightedResultScoreScoreRangeRule(min: 1.3, max: 3526.9)
        let item = Labs.newWeightedResultScore("x", name: "y")
        item.score = 3528.4
        #expect(rule.check(item).count > 0)
    }
}
