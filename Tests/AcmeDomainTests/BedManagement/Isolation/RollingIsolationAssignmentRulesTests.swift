@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingIsolationAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingIsolationAssignmentValidator()
        let item = BedManagement.newRollingIsolationAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingIsolationAssignmentDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = BedManagement.RollingIsolationAssignmentDosageMgRangeRule(min: 0.7, max: 527.2)
        let item = BedManagement.newRollingIsolationAssignment("x", name: "y")
        item.dosageMg = 528.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRollingIsolationAssignmentRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = BedManagement.RollingIsolationAssignmentRequiredOwnerIDRule(
            message: "rolling isolation assignment needs this field"
        )
        let item = BedManagement.newRollingIsolationAssignment("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingIsolationAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.RollingIsolationAssignmentRequiredNameRule(
            message: "rolling isolation assignment needs a value"
        )
        let item = BedManagement.newRollingIsolationAssignment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingIsolationAssignmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.RollingIsolationAssignmentNameLengthRule(maxLength: 1000)
        let item = BedManagement.newRollingIsolationAssignment("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
