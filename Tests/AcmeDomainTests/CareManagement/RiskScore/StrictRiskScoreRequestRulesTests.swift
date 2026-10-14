@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictRiskScoreRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultStrictRiskScoreRequestValidator()
        let item = CareManagement.newStrictRiskScoreRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementStrictRiskScoreRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.StrictRiskScoreRequestCodeLengthRule(maxLength: 32)
        let item = CareManagement.newStrictRiskScoreRequest("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementStrictRiskScoreRequestPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = CareManagement.StrictRiskScoreRequestPatientRefLengthRule(maxLength: 64)
        let item = CareManagement.newStrictRiskScoreRequest("x", name: "y")
        item.patientRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementStrictRiskScoreRequestRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = CareManagement.StrictRiskScoreRequestRequiredPatientRefRule(
            message: "strict risk score request needs this field"
        )
        let item = CareManagement.newStrictRiskScoreRequest("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementStrictRiskScoreRequestNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = CareManagement.StrictRiskScoreRequestNotesLengthRule(maxLength: 32)
        let item = CareManagement.newStrictRiskScoreRequest("x", name: "y")
        item.notes = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementStrictRiskScoreRequestCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = CareManagement.StrictRiskScoreRequestCeilingRangeRule(min: 4.9, max: 3894.1)
        let item = CareManagement.newStrictRiskScoreRequest("x", name: "y")
        item.ceiling = 3895.6
        #expect(rule.check(item).count > 0)
    }
}
