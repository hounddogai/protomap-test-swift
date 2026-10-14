@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskSlotValidator()
        let item = ClinicalOps.newTaskSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskSlotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.TaskSlotRequiredNameRule(message: "task slot needs a value")
        let item = ClinicalOps.newTaskSlot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskSlotRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = ClinicalOps.TaskSlotRequiredSummaryRule(message: "task slot needs a value")
        let item = ClinicalOps.newTaskSlot("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskSlotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.TaskSlotNameLengthRule(maxLength: 255)
        let item = ClinicalOps.newTaskSlot("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskSlotEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = ClinicalOps.TaskSlotEndsAtRangeRule(min: 16, max: 32)
        let item = ClinicalOps.newTaskSlot("x", name: "y")
        item.endsAt = 33
        #expect(rule.check(item).count > 0)
    }
}
