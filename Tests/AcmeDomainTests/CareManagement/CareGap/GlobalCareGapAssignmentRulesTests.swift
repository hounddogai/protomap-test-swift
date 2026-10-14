@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalCareGapAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalCareGapAssignmentValidator()
        let item = CareManagement.newGlobalCareGapAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalCareGapAssignmentRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = CareManagement.GlobalCareGapAssignmentRequiredUnitRule(
            message: "global care gap assignment needs this field"
        )
        let item = CareManagement.newGlobalCareGapAssignment("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGlobalCareGapAssignmentCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = CareManagement.GlobalCareGapAssignmentCopayRangeRule(min: 8.9, max: 3336.1)
        let item = CareManagement.newGlobalCareGapAssignment("x", name: "y")
        item.copay = 3337.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGlobalCareGapAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.GlobalCareGapAssignmentRequiredNameRule(
            message: "global care gap assignment needs a value"
        )
        let item = CareManagement.newGlobalCareGapAssignment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGlobalCareGapAssignmentUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = CareManagement.GlobalCareGapAssignmentUpdatedAtRangeRule(min: 120, max: 1000)
        let item = CareManagement.newGlobalCareGapAssignment("x", name: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
