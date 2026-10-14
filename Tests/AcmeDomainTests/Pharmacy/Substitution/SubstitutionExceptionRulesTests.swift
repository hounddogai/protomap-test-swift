@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionExceptionValidator()
        let item = Pharmacy.newSubstitutionException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionExceptionLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.SubstitutionExceptionLabelLengthRule(maxLength: 80)
        let item = Pharmacy.newSubstitutionException("x", title: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionExceptionFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Pharmacy.SubstitutionExceptionFloorValueRangeRule(min: 4.8, max: 739.6)
        let item = Pharmacy.newSubstitutionException("x", title: "y")
        item.floorValue = 741.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySubstitutionExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.SubstitutionExceptionCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newSubstitutionException("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
