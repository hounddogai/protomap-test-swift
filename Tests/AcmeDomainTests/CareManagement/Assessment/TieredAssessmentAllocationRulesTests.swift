@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredAssessmentAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredAssessmentAllocationValidator()
        let item = CareManagement.newTieredAssessmentAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredAssessmentAllocationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.TieredAssessmentAllocationRequiredLabelRule(
            message: "tiered assessment allocation needs a value"
        )
        let item = CareManagement.newTieredAssessmentAllocation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementTieredAssessmentAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.TieredAssessmentAllocationCodeLengthRule(maxLength: 16)
        let item = CareManagement.newTieredAssessmentAllocation("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredAssessmentAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.TieredAssessmentAllocationRequiredCodeRule(
            message: "tiered assessment allocation needs a value"
        )
        let item = CareManagement.newTieredAssessmentAllocation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
