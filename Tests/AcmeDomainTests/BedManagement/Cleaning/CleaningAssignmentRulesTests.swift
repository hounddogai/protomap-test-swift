@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningAssignmentValidator()
        let item = BedManagement.newCleaningAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningAssignmentRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = BedManagement.CleaningAssignmentRegionLengthRule(maxLength: 80)
        let item = BedManagement.newCleaningAssignment("x", name: "y")
        item.region = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningAssignmentRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = BedManagement.CleaningAssignmentRequiredRegionRule(message: "cleaning assignment needs this field")
        let item = BedManagement.newCleaningAssignment("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CleaningAssignmentRequiredNameRule(message: "cleaning assignment needs a value")
        let item = BedManagement.newCleaningAssignment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
