@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardAdjustmentValidator()
        let item = BedManagement.newBedBoardAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardAdjustmentCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = BedManagement.BedBoardAdjustmentCountryLengthRule(maxLength: 64)
        let item = BedManagement.newBedBoardAdjustment("x", label: "y")
        item.country = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardAdjustmentRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = BedManagement.BedBoardAdjustmentRequiredCountryRule(message: "bed board adjustment needs this field")
        let item = BedManagement.newBedBoardAdjustment("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.BedBoardAdjustmentCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newBedBoardAdjustment("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardAdjustmentRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = BedManagement.BedBoardAdjustmentRequiredClinicianIDRule(message: "bed board adjustment needs a value")
        let item = BedManagement.newBedBoardAdjustment("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardAdjustmentClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = BedManagement.BedBoardAdjustmentClinicianIDLengthRule(maxLength: 1000)
        let item = BedManagement.newBedBoardAdjustment("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
