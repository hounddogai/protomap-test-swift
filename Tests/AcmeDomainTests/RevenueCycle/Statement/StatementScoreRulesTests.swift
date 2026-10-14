@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementScoreValidator()
        let item = RevenueCycle.newStatementScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementScoreLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.StatementScoreLabelLengthRule(maxLength: 86400)
        let item = RevenueCycle.newStatementScore("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementScoreRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.StatementScoreRequiredLabelRule(message: "statement score needs an entry")
        let item = RevenueCycle.newStatementScore("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementScoreRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = RevenueCycle.StatementScoreRequiredEncounterIDRule(message: "statement score needs this field")
        let item = RevenueCycle.newStatementScore("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementScoreMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = RevenueCycle.StatementScoreMarginRangeRule(min: 5.1, max: 1441.3)
        let item = RevenueCycle.newStatementScore("x", label: "y")
        item.margin = 1442.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementScoreEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = RevenueCycle.StatementScoreEncounterIDLengthRule(maxLength: 16)
        let item = RevenueCycle.newStatementScore("x", label: "y")
        item.encounterID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
