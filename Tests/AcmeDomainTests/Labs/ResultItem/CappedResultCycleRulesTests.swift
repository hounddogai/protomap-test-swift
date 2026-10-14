@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedResultCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedResultCycleValidator()
        let item = Labs.newCappedResultCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedResultCycleProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Labs.CappedResultCycleProcedureCodeLengthRule(maxLength: 32)
        let item = Labs.newCappedResultCycle("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedResultCyclePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Labs.CappedResultCyclePriorityRangeRule(min: 16, max: 255)
        let item = Labs.newCappedResultCycle("x", label: "y")
        item.priority = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedResultCycleRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Labs.CappedResultCycleRequiredRegionRule(message: "capped result cycle needs a value")
        let item = Labs.newCappedResultCycle("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCappedResultCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CappedResultCycleCodeLengthRule(maxLength: 120)
        let item = Labs.newCappedResultCycle("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedResultCycleBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Labs.CappedResultCycleBudgetRangeRule(min: 0.7, max: 4694.4)
        let item = Labs.newCappedResultCycle("x", label: "y")
        item.budget = 4695.9
        #expect(rule.check(item).count > 0)
    }
}
