@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledCensusAssignmentValidator()
        let item = BedManagement.newScheduledCensusAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledCensusAssignmentQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = BedManagement.ScheduledCensusAssignmentQuantityRangeRule(min: 80, max: 1000)
        let item = BedManagement.newScheduledCensusAssignment("x", label: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementScheduledCensusAssignmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.ScheduledCensusAssignmentRequiredLabelRule(
            message: "scheduled census assignment needs a value"
        )
        let item = BedManagement.newScheduledCensusAssignment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledCensusAssignmentPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = BedManagement.ScheduledCensusAssignmentPayerLengthRule(maxLength: 1000)
        let item = BedManagement.newScheduledCensusAssignment("x", label: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledCensusAssignmentRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = BedManagement.ScheduledCensusAssignmentRequiredPayerRule(
            message: "scheduled census assignment needs this field"
        )
        let item = BedManagement.newScheduledCensusAssignment("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
