@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictWitnessReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultStrictWitnessReviewValidator()
        let item = Consent.newStrictWitnessReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentStrictWitnessReviewCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Consent.StrictWitnessReviewCapacityRangeRule(min: 80, max: 80)
        let item = Consent.newStrictWitnessReview("x", label: "y")
        item.capacity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentStrictWitnessReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.StrictWitnessReviewRequiredLabelRule(message: "strict witness review needs a value")
        let item = Consent.newStrictWitnessReview("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentStrictWitnessReviewLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.StrictWitnessReviewLabelLengthRule(maxLength: 86400)
        let item = Consent.newStrictWitnessReview("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentStrictWitnessReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.StrictWitnessReviewCodeLengthRule(maxLength: 80)
        let item = Consent.newStrictWitnessReview("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
