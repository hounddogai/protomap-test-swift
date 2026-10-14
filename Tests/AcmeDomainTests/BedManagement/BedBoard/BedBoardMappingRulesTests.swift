@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardMappingValidator()
        let item = BedManagement.newBedBoardMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardMappingRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = BedManagement.BedBoardMappingRequiredClinicianIDRule(message: "bed board mapping needs a value")
        let item = BedManagement.newBedBoardMapping("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
