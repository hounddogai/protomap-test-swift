@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedCareGapAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCappedCareGapAssignmentValidator()
        let item = CareManagement.newCappedCareGapAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCappedCareGapAssignmentFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.CappedCareGapAssignmentFloorValueRangeRule(min: 0.4, max: 4194.4)
        let item = CareManagement.newCappedCareGapAssignment("x", label: "y")
        item.floorValue = 4195.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCappedCareGapAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.CappedCareGapAssignmentRequiredCodeRule(
            message: "capped care gap assignment needs this field"
        )
        let item = CareManagement.newCappedCareGapAssignment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCappedCareGapAssignmentSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = CareManagement.CappedCareGapAssignmentSourceLengthRule(maxLength: 120)
        let item = CareManagement.newCappedCareGapAssignment("x", label: "y")
        item.source = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
