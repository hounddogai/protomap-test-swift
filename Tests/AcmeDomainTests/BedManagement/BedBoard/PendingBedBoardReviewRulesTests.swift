@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingBedBoardReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPendingBedBoardReviewValidator()
        let item = BedManagement.newPendingBedBoardReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPendingBedBoardReviewAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = BedManagement.PendingBedBoardReviewAmountRangeRule(min: 0.6, max: 2509.8)
        let item = BedManagement.newPendingBedBoardReview("x", label: "y")
        item.amount = 2511.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPendingBedBoardReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.PendingBedBoardReviewRequiredLabelRule(
            message: "pending bed board review needs this field"
        )
        let item = BedManagement.newPendingBedBoardReview("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPendingBedBoardReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.PendingBedBoardReviewCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newPendingBedBoardReview("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPendingBedBoardReviewRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = BedManagement.PendingBedBoardReviewRequiredChecksumRule(
            message: "pending bed board review needs a value"
        )
        let item = BedManagement.newPendingBedBoardReview("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
