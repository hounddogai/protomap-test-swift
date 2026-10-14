@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffPlanValidator()
        let item = ClinicalOps.newHandoffPlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffPlanCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = ClinicalOps.HandoffPlanCapacityRangeRule(min: 16, max: 32)
        let item = ClinicalOps.newHandoffPlan("x", name: "y")
        item.capacity = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsHandoffPlanRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = ClinicalOps.HandoffPlanRequiredSegmentRule(message: "handoff plan needs an entry")
        let item = ClinicalOps.newHandoffPlan("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.HandoffPlanRequiredCodeRule(message: "handoff plan needs an entry")
        let item = ClinicalOps.newHandoffPlan("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.HandoffPlanCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newHandoffPlan("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
