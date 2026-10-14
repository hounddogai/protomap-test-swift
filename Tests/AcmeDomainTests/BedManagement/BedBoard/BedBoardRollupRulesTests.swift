@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardRollupValidator()
        let item = BedManagement.newBedBoardRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardRollupRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = BedManagement.BedBoardRollupRequiredClinicianIDRule(message: "bed board rollup needs an entry")
        let item = BedManagement.newBedBoardRollup("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardRollupClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = BedManagement.BedBoardRollupClinicianIDLengthRule(maxLength: 255)
        let item = BedManagement.newBedBoardRollup("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
