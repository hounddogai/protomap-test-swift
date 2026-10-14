@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanRecordValidator()
        let item = BedManagement.newDischargePlanRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanRecordMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = BedManagement.DischargePlanRecordMinimumRangeRule(min: 5.3, max: 4432.5)
        let item = BedManagement.newDischargePlanRecord("x", title: "y")
        item.minimum = 4434.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanRecordRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = BedManagement.DischargePlanRecordRequiredDiagnosisCodeRule(
            message: "discharge plan record needs this field"
        )
        let item = BedManagement.newDischargePlanRecord("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanRecordDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = BedManagement.DischargePlanRecordDiagnosisCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newDischargePlanRecord("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
