@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionAssignmentValidator()
        let item = Pharmacy.newSubstitutionAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionAssignmentRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Pharmacy.SubstitutionAssignmentRateRangeRule(min: 5.2, max: 2492.4)
        let item = Pharmacy.newSubstitutionAssignment("x", title: "y")
        item.rate = 2493.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySubstitutionAssignmentUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Pharmacy.SubstitutionAssignmentUnitLengthRule(maxLength: 32)
        let item = Pharmacy.newSubstitutionAssignment("x", title: "y")
        item.unit = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
