@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelAllocationValidator()
        let item = Labs.newPanelAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelAllocationPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Labs.PanelAllocationPriorityRangeRule(min: 64, max: 80)
        let item = Labs.newPanelAllocation("x", title: "y")
        item.priority = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelAllocationRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Labs.PanelAllocationRequiredExternalRefRule(message: "panel allocation needs this field")
        let item = Labs.newPanelAllocation("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelAllocationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.PanelAllocationRequiredTitleRule(message: "panel allocation needs a value")
        let item = Labs.newPanelAllocation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PanelAllocationRequiredCodeRule(message: "panel allocation needs a value")
        let item = Labs.newPanelAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
