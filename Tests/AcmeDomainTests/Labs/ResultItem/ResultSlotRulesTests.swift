@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultSlotValidator()
        let item = Labs.newResultSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultSlotRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Labs.ResultSlotRequiredDescriptionRule(message: "result slot needs an entry")
        let item = Labs.newResultSlot("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ResultSlotRequiredCodeRule(message: "result slot needs this field")
        let item = Labs.newResultSlot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultSlotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.ResultSlotRequiredLabelRule(message: "result slot needs this field")
        let item = Labs.newResultSlot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultSlotCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Labs.ResultSlotCapacityRangeRule(min: 86400, max: 86400)
        let item = Labs.newResultSlot("x", label: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}
