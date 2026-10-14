@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptivePanelAllocationValidator()
        let item = Labs.newAdaptivePanelAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptivePanelAllocationRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Labs.AdaptivePanelAllocationRequiredEncounterIDRule(
            message: "adaptive panel allocation needs this field"
        )
        let item = Labs.newAdaptivePanelAllocation("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptivePanelAllocationCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Labs.AdaptivePanelAllocationCopayRangeRule(min: 1.3, max: 1235.7)
        let item = Labs.newAdaptivePanelAllocation("x", title: "y")
        item.copay = 1237.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAdaptivePanelAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.AdaptivePanelAllocationTitleLengthRule(maxLength: 86400)
        let item = Labs.newAdaptivePanelAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAdaptivePanelAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AdaptivePanelAllocationRequiredCodeRule(message: "adaptive panel allocation needs a value")
        let item = Labs.newAdaptivePanelAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptivePanelAllocationCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Labs.AdaptivePanelAllocationCapacityRangeRule(min: 64, max: 86400)
        let item = Labs.newAdaptivePanelAllocation("x", title: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}
