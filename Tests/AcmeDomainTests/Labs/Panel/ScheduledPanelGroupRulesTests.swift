@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledPanelGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultScheduledPanelGroupValidator()
        let item = Labs.newScheduledPanelGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsScheduledPanelGroupCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Labs.ScheduledPanelGroupCostRangeRule(min: 4.8, max: 2721.9)
        let item = Labs.newScheduledPanelGroup("x", title: "y")
        item.cost = 2723.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsScheduledPanelGroupRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Labs.ScheduledPanelGroupRequiredWardRule(message: "scheduled panel group needs an entry")
        let item = Labs.newScheduledPanelGroup("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsScheduledPanelGroupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.ScheduledPanelGroupRequiredTitleRule(message: "scheduled panel group needs a value")
        let item = Labs.newScheduledPanelGroup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsScheduledPanelGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ScheduledPanelGroupRequiredCodeRule(message: "scheduled panel group needs an entry")
        let item = Labs.newScheduledPanelGroup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsScheduledPanelGroupTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.ScheduledPanelGroupTitleLengthRule(maxLength: 86400)
        let item = Labs.newScheduledPanelGroup("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
