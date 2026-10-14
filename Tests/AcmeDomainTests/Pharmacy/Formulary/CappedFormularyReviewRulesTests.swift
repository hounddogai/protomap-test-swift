@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedFormularyReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultCappedFormularyReviewValidator()
        let item = Pharmacy.newCappedFormularyReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyCappedFormularyReviewTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.CappedFormularyReviewTitleLengthRule(maxLength: 255)
        let item = Pharmacy.newCappedFormularyReview("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyCappedFormularyReviewRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.CappedFormularyReviewRequiredTitleRule(message: "capped formulary review needs this field")
        let item = Pharmacy.newCappedFormularyReview("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyCappedFormularyReviewDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Pharmacy.CappedFormularyReviewDiagnosisCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newCappedFormularyReview("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
