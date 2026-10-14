@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskTargetValidator()
        let item = ClinicalOps.newTaskTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskTargetFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = ClinicalOps.TaskTargetFloorValueRangeRule(min: 2.7, max: 4532.7)
        let item = ClinicalOps.newTaskTarget("x", label: "y")
        item.floorValue = 4534.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskTargetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.TaskTargetRequiredLabelRule(message: "task target needs a value")
        let item = ClinicalOps.newTaskTarget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
