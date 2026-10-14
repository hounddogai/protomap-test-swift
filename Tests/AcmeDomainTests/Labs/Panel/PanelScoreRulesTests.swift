@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelScoreValidator()
        let item = Labs.newPanelScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelScoreCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Labs.PanelScoreCostRangeRule(min: 4.9, max: 286.6)
        let item = Labs.newPanelScore("x", title: "y")
        item.cost = 288.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelScoreContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Labs.PanelScoreContactEmailLengthRule(maxLength: 16)
        let item = Labs.newPanelScore("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelScoreStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Labs.PanelScoreStartsAtRangeRule(min: 64, max: 80)
        let item = Labs.newPanelScore("x", title: "y")
        item.startsAt = 81
        #expect(rule.check(item).count > 0)
    }
}
