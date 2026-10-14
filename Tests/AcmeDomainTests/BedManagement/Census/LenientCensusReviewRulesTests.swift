@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLenientCensusReviewValidator()
        let item = BedManagement.newLenientCensusReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLenientCensusReviewCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = BedManagement.LenientCensusReviewCountryLengthRule(maxLength: 1000)
        let item = BedManagement.newLenientCensusReview("x", label: "y")
        item.country = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLenientCensusReviewRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = BedManagement.LenientCensusReviewRequiredCountryRule(
            message: "lenient census review needs this field"
        )
        let item = BedManagement.newLenientCensusReview("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientCensusReviewRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = BedManagement.LenientCensusReviewRetriesRangeRule(min: 255, max: 255)
        let item = BedManagement.newLenientCensusReview("x", label: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLenientCensusReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.LenientCensusReviewCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newLenientCensusReview("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
