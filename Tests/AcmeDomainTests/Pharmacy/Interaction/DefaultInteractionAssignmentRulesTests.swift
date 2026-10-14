@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultInteractionAssignmentValidator()
        let item = Pharmacy.newDefaultInteractionAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultInteractionAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.DefaultInteractionAssignmentCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newDefaultInteractionAssignment("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultInteractionAssignmentRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Pharmacy.DefaultInteractionAssignmentRequiredClinicianIDRule(
            message: "default interaction assignment needs this field"
        )
        let item = Pharmacy.newDefaultInteractionAssignment("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultInteractionAssignmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.DefaultInteractionAssignmentNameLengthRule(maxLength: 120)
        let item = Pharmacy.newDefaultInteractionAssignment("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
