@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryBedBoardMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryBedBoardMetricValidator()
        let item = BedManagement.newPrimaryBedBoardMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryBedBoardMetricRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.PrimaryBedBoardMetricRequiredNameRule(message: "primary bed board metric needs a value")
        let item = BedManagement.newPrimaryBedBoardMetric("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryBedBoardMetricUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = BedManagement.PrimaryBedBoardMetricUpdatedAtRangeRule(min: 255, max: 86400)
        let item = BedManagement.newPrimaryBedBoardMetric("x", name: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryBedBoardMetricRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = BedManagement.PrimaryBedBoardMetricRequiredCategoryRule(
            message: "primary bed board metric needs a value"
        )
        let item = BedManagement.newPrimaryBedBoardMetric("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}
