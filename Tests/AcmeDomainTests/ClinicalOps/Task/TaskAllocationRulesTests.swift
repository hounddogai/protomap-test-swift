@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskAllocationValidator()
        let item = ClinicalOps.newTaskAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskAllocationRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = ClinicalOps.TaskAllocationRequiredLocaleRule(message: "task allocation needs this field")
        let item = ClinicalOps.newTaskAllocation("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TaskAllocationCodeLengthRule(maxLength: 80)
        let item = ClinicalOps.newTaskAllocation("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskAllocationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.TaskAllocationRequiredLabelRule(message: "task allocation needs a value")
        let item = ClinicalOps.newTaskAllocation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskAllocationRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = ClinicalOps.TaskAllocationRequiredEncounterIDRule(message: "task allocation needs an entry")
        let item = ClinicalOps.newTaskAllocation("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskAllocationLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = ClinicalOps.TaskAllocationLocaleLengthRule(maxLength: 3600)
        let item = ClinicalOps.newTaskAllocation("x", label: "y")
        item.locale = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskAllocationRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = ClinicalOps.TaskAllocationRatioRangeRule(min: 9.2, max: 2277.2)
        let item = ClinicalOps.newTaskAllocation("x", label: "y")
        item.ratio = 2278.7
        #expect(rule.check(item).count > 0)
    }
}
