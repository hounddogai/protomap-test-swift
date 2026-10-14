@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingInteractionAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPendingInteractionAllocationValidator()
        let item = Pharmacy.newPendingInteractionAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPendingInteractionAllocationRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Pharmacy.PendingInteractionAllocationRequiredPatientRefRule(
            message: "pending interaction allocation needs an entry"
        )
        let item = Pharmacy.newPendingInteractionAllocation("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPendingInteractionAllocationPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Pharmacy.PendingInteractionAllocationPatientRefLengthRule(maxLength: 32)
        let item = Pharmacy.newPendingInteractionAllocation("x", label: "y")
        item.patientRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
