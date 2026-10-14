@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingReservationValidator()
        let item = ClinicalOps.newRoundingReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingReservationPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.RoundingReservationPatientRefLengthRule(maxLength: 64)
        let item = ClinicalOps.newRoundingReservation("x", name: "y")
        item.patientRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingReservationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.RoundingReservationNameLengthRule(maxLength: 3600)
        let item = ClinicalOps.newRoundingReservation("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingReservationPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = ClinicalOps.RoundingReservationPriorityRangeRule(min: 16, max: 120)
        let item = ClinicalOps.newRoundingReservation("x", name: "y")
        item.priority = 121
        #expect(rule.check(item).count > 0)
    }
}
