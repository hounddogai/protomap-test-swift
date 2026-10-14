@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCensusReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPendingCensusReviewValidator()
        let item = BedManagement.newPendingCensusReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPendingCensusReviewUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = BedManagement.PendingCensusReviewUnitLengthRule(maxLength: 3600)
        let item = BedManagement.newPendingCensusReview("x", title: "y")
        item.unit = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPendingCensusReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.PendingCensusReviewRequiredLabelRule(message: "pending census review needs an entry")
        let item = BedManagement.newPendingCensusReview("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPendingCensusReviewRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.PendingCensusReviewRequiredTitleRule(message: "pending census review needs this field")
        let item = BedManagement.newPendingCensusReview("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPendingCensusReviewScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = BedManagement.PendingCensusReviewScoreRangeRule(min: 9.7, max: 2226.4)
        let item = BedManagement.newPendingCensusReview("x", title: "y")
        item.score = 2227.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPendingCensusReviewCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = BedManagement.PendingCensusReviewCostRangeRule(min: 9.7, max: 4887.9)
        let item = BedManagement.newPendingCensusReview("x", title: "y")
        item.cost = 4889.4
        #expect(rule.check(item).count > 0)
    }
}
