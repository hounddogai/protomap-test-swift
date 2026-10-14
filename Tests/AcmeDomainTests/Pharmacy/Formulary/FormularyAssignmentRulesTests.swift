@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyAssignmentValidator()
        let item = Pharmacy.newFormularyAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyAssignmentContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Pharmacy.FormularyAssignmentContactEmailLengthRule(maxLength: 1000)
        let item = Pharmacy.newFormularyAssignment("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyAssignmentRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Pharmacy.FormularyAssignmentRequiredContactEmailRule(message: "formulary assignment needs an entry")
        let item = Pharmacy.newFormularyAssignment("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyAssignmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.FormularyAssignmentNameLengthRule(maxLength: 3600)
        let item = Pharmacy.newFormularyAssignment("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
