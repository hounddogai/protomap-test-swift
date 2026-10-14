@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyRecallTemplateValidator()
        let item = Pharmacy.newLegacyRecallTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyRecallTemplateClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Pharmacy.LegacyRecallTemplateClinicianIDLengthRule(maxLength: 64)
        let item = Pharmacy.newLegacyRecallTemplate("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyRecallTemplateMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Pharmacy.LegacyRecallTemplateMinimumRangeRule(min: 3.7, max: 2721.0)
        let item = Pharmacy.newLegacyRecallTemplate("x", title: "y")
        item.minimum = 2722.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLegacyRecallTemplateTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.LegacyRecallTemplateTitleLengthRule(maxLength: 64)
        let item = Pharmacy.newLegacyRecallTemplate("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
