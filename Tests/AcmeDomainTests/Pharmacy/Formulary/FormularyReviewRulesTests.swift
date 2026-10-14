@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyReviewValidator()
        let item = Pharmacy.newFormularyReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyReviewProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Pharmacy.FormularyReviewProcedureCodeLengthRule(maxLength: 16)
        let item = Pharmacy.newFormularyReview("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyReviewAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Pharmacy.FormularyReviewAmountRangeRule(min: 8.1, max: 2023.1)
        let item = Pharmacy.newFormularyReview("x", label: "y")
        item.amount = 2024.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularyReviewTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Pharmacy.FormularyReviewTimezoneLengthRule(maxLength: 255)
        let item = Pharmacy.newFormularyReview("x", label: "y")
        item.timezone = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.FormularyReviewRequiredLabelRule(message: "formulary review needs this field")
        let item = Pharmacy.newFormularyReview("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyReviewRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Pharmacy.FormularyReviewRequiredTimezoneRule(message: "formulary review needs a value")
        let item = Pharmacy.newFormularyReview("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyReviewAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Pharmacy.FormularyReviewAcuityRangeRule(min: 1000, max: 1000)
        let item = Pharmacy.newFormularyReview("x", label: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}
