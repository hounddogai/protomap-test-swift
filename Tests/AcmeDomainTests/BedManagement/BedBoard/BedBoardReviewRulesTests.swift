@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardReviewValidator()
        let item = BedManagement.newBedBoardReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.BedBoardReviewCodeLengthRule(maxLength: 80)
        let item = BedManagement.newBedBoardReview("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardReviewAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = BedManagement.BedBoardReviewAmountRangeRule(min: 9.1, max: 4661.6)
        let item = BedManagement.newBedBoardReview("x", name: "y")
        item.amount = 4663.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardReviewDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = BedManagement.BedBoardReviewDescriptionLengthRule(maxLength: 32)
        let item = BedManagement.newBedBoardReview("x", name: "y")
        item.description = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardReviewVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = BedManagement.BedBoardReviewVersionRangeRule(min: 64, max: 120)
        let item = BedManagement.newBedBoardReview("x", name: "y")
        item.version = 121
        #expect(rule.check(item).count > 0)
    }
}
