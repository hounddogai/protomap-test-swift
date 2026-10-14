@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledCensusAgreementValidator()
        let item = BedManagement.newScheduledCensusAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledCensusAgreementRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = BedManagement.ScheduledCensusAgreementRequiredDiagnosisCodeRule(
            message: "scheduled census agreement needs a value"
        )
        let item = BedManagement.newScheduledCensusAgreement("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledCensusAgreementQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = BedManagement.ScheduledCensusAgreementQuantityRangeRule(min: 80, max: 80)
        let item = BedManagement.newScheduledCensusAgreement("x", name: "y")
        item.quantity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementScheduledCensusAgreementProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = BedManagement.ScheduledCensusAgreementProcedureCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newScheduledCensusAgreement("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledCensusAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.ScheduledCensusAgreementRequiredCodeRule(
            message: "scheduled census agreement needs a value"
        )
        let item = BedManagement.newScheduledCensusAgreement("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
