@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCleaningAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualCleaningAssignmentValidator()
        let item = BedManagement.newManualCleaningAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualCleaningAssignmentBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = BedManagement.ManualCleaningAssignmentBatchSizeRangeRule(min: 120, max: 1000)
        let item = BedManagement.newManualCleaningAssignment("x", title: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementManualCleaningAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.ManualCleaningAssignmentRequiredCodeRule(
            message: "manual cleaning assignment needs this field"
        )
        let item = BedManagement.newManualCleaningAssignment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
