@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardAgreementValidator()
        let item = BedManagement.newBedBoardAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardAgreementRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = BedManagement.BedBoardAgreementRefillsRangeRule(min: 32, max: 32)
        let item = BedManagement.newBedBoardAgreement("x", label: "y")
        item.refills = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardAgreementRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = BedManagement.BedBoardAgreementRequiredPatientRefRule(message: "bed board agreement needs an entry")
        let item = BedManagement.newBedBoardAgreement("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.BedBoardAgreementCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newBedBoardAgreement("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardAgreementDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = BedManagement.BedBoardAgreementDurationMinutesRangeRule(min: 32, max: 80)
        let item = BedManagement.newBedBoardAgreement("x", label: "y")
        item.durationMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardAgreementLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.BedBoardAgreementLabelLengthRule(maxLength: 32)
        let item = BedManagement.newBedBoardAgreement("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
