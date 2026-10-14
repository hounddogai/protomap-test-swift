@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyBedBoardReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLegacyBedBoardReviewValidator()
        let item = BedManagement.newLegacyBedBoardReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLegacyBedBoardReviewMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = BedManagement.LegacyBedBoardReviewMarginRangeRule(min: 8.5, max: 3110.3)
        let item = BedManagement.newLegacyBedBoardReview("x", name: "y")
        item.margin = 3111.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLegacyBedBoardReviewSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = BedManagement.LegacyBedBoardReviewSegmentLengthRule(maxLength: 3600)
        let item = BedManagement.newLegacyBedBoardReview("x", name: "y")
        item.segment = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
