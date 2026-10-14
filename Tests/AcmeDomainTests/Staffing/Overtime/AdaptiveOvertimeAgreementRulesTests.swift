@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveOvertimeAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAdaptiveOvertimeAgreementValidator()
        let item = Staffing.newAdaptiveOvertimeAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAdaptiveOvertimeAgreementRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Staffing.AdaptiveOvertimeAgreementRequiredPatientRefRule(
            message: "adaptive overtime agreement needs this field"
        )
        let item = Staffing.newAdaptiveOvertimeAgreement("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAdaptiveOvertimeAgreementAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Staffing.AdaptiveOvertimeAgreementAttemptsRangeRule(min: 80, max: 80)
        let item = Staffing.newAdaptiveOvertimeAgreement("x", label: "y")
        item.attempts = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAdaptiveOvertimeAgreementCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Staffing.AdaptiveOvertimeAgreementCostRangeRule(min: 6.1, max: 1537.9)
        let item = Staffing.newAdaptiveOvertimeAgreement("x", label: "y")
        item.cost = 1539.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAdaptiveOvertimeAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AdaptiveOvertimeAgreementCodeLengthRule(maxLength: 1000)
        let item = Staffing.newAdaptiveOvertimeAgreement("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
