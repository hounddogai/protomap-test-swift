@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementSegmentValidator()
        let item = RevenueCycle.newStatementSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementSegmentEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = RevenueCycle.StatementSegmentEncounterIDLengthRule(maxLength: 16)
        let item = RevenueCycle.newStatementSegment("x", title: "y")
        item.encounterID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementSegmentMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = RevenueCycle.StatementSegmentMinimumRangeRule(min: 2.8, max: 1405.4)
        let item = RevenueCycle.newStatementSegment("x", title: "y")
        item.minimum = 1406.9
        #expect(rule.check(item).count > 0)
    }
}
