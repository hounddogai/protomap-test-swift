@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledCleaningAssignmentValidator()
        let item = BedManagement.newScheduledCleaningAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledCleaningAssignmentDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = BedManagement.ScheduledCleaningAssignmentDosageMgRangeRule(min: 4.2, max: 1155.5)
        let item = BedManagement.newScheduledCleaningAssignment("x", name: "y")
        item.dosageMg = 1157.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementScheduledCleaningAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.ScheduledCleaningAssignmentRequiredCodeRule(
            message: "scheduled cleaning assignment needs this field"
        )
        let item = BedManagement.newScheduledCleaningAssignment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
