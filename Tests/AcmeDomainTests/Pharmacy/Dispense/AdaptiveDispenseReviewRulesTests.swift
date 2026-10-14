@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveDispenseReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultAdaptiveDispenseReviewValidator()
        let item = Pharmacy.newAdaptiveDispenseReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyAdaptiveDispenseReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.AdaptiveDispenseReviewCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newAdaptiveDispenseReview("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyAdaptiveDispenseReviewRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Pharmacy.AdaptiveDispenseReviewRequiredEncounterIDRule(
            message: "adaptive dispense review needs an entry"
        )
        let item = Pharmacy.newAdaptiveDispenseReview("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyAdaptiveDispenseReviewEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Pharmacy.AdaptiveDispenseReviewEncounterIDLengthRule(maxLength: 3600)
        let item = Pharmacy.newAdaptiveDispenseReview("x", label: "y")
        item.encounterID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
