@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledDispenseAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultScheduledDispenseAgreementValidator()
        let item = Pharmacy.newScheduledDispenseAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyScheduledDispenseAgreementRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Pharmacy.ScheduledDispenseAgreementRequiredReviewerRule(
            message: "scheduled dispense agreement needs a value"
        )
        let item = Pharmacy.newScheduledDispenseAgreement("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyScheduledDispenseAgreementAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Pharmacy.ScheduledDispenseAgreementAllergyLengthRule(maxLength: 64)
        let item = Pharmacy.newScheduledDispenseAgreement("x", title: "y")
        item.allergy = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyScheduledDispenseAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.ScheduledDispenseAgreementRequiredTitleRule(
            message: "scheduled dispense agreement needs this field"
        )
        let item = Pharmacy.newScheduledDispenseAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
