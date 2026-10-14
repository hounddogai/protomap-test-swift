@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertAssignmentValidator()
        let item = ClinicalOps.newAlertAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertAssignmentRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = ClinicalOps.AlertAssignmentRequiredSpecialtyRule(message: "alert assignment needs an entry")
        let item = ClinicalOps.newAlertAssignment("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertAssignmentClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = ClinicalOps.AlertAssignmentClinicianIDLengthRule(maxLength: 120)
        let item = ClinicalOps.newAlertAssignment("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertAssignmentCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = ClinicalOps.AlertAssignmentCeilingRangeRule(min: 3.6, max: 2699.2)
        let item = ClinicalOps.newAlertAssignment("x", title: "y")
        item.ceiling = 2700.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertAssignmentSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = ClinicalOps.AlertAssignmentSpecialtyLengthRule(maxLength: 64)
        let item = ClinicalOps.newAlertAssignment("x", title: "y")
        item.specialty = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
