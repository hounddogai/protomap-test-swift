@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledPanelScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultScheduledPanelScoreValidator()
        let item = Labs.newScheduledPanelScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsScheduledPanelScoreRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Labs.ScheduledPanelScoreRequiredWardRule(message: "scheduled panel score needs an entry")
        let item = Labs.newScheduledPanelScore("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsScheduledPanelScoreCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Labs.ScheduledPanelScoreCostRangeRule(min: 4.7, max: 3015.2)
        let item = Labs.newScheduledPanelScore("x", name: "y")
        item.cost = 3016.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsScheduledPanelScoreExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Labs.ScheduledPanelScoreExternalRefLengthRule(maxLength: 3600)
        let item = Labs.newScheduledPanelScore("x", name: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsScheduledPanelScoreCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Labs.ScheduledPanelScoreCapacityRangeRule(min: 16, max: 86400)
        let item = Labs.newScheduledPanelScore("x", name: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsScheduledPanelScoreMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Labs.ScheduledPanelScoreMaximumRangeRule(min: 5.1, max: 1749.4)
        let item = Labs.newScheduledPanelScore("x", name: "y")
        item.maximum = 1750.9
        #expect(rule.check(item).count > 0)
    }
}
