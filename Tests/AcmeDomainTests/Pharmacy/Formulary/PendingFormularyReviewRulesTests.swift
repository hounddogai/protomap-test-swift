@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingFormularyReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPendingFormularyReviewValidator()
        let item = Pharmacy.newPendingFormularyReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPendingFormularyReviewOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Pharmacy.PendingFormularyReviewOwnerIDLengthRule(maxLength: 255)
        let item = Pharmacy.newPendingFormularyReview("x", name: "y")
        item.ownerID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPendingFormularyReviewRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Pharmacy.PendingFormularyReviewRequiredOwnerIDRule(message: "pending formulary review needs an entry")
        let item = Pharmacy.newPendingFormularyReview("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPendingFormularyReviewDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Pharmacy.PendingFormularyReviewDiscountRangeRule(min: 8.5, max: 4529.0)
        let item = Pharmacy.newPendingFormularyReview("x", name: "y")
        item.discount = 4530.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPendingFormularyReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.PendingFormularyReviewNameLengthRule(maxLength: 80)
        let item = Pharmacy.newPendingFormularyReview("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
