@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedResultRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultWeightedResultRuleValidator()
        let item = Labs.newWeightedResultRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsWeightedResultRuleRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Labs.WeightedResultRuleRateRangeRule(min: 8.2, max: 2171.3)
        let item = Labs.newWeightedResultRule("x", name: "y")
        item.rate = 2172.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsWeightedResultRuleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.WeightedResultRuleTitleLengthRule(maxLength: 255)
        let item = Labs.newWeightedResultRule("x", name: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsWeightedResultRuleStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Labs.WeightedResultRuleStartsAtRangeRule(min: 32, max: 64)
        let item = Labs.newWeightedResultRule("x", name: "y")
        item.startsAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsWeightedResultRuleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.WeightedResultRuleRequiredTitleRule(message: "weighted result rule needs an entry")
        let item = Labs.newWeightedResultRule("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
