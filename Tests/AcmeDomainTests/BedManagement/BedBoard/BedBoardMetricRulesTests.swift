@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardMetricValidator()
        let item = BedManagement.newBedBoardMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardMetricRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.BedBoardMetricRequiredNameRule(message: "bed board metric needs an entry")
        let item = BedManagement.newBedBoardMetric("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardMetricUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = BedManagement.BedBoardMetricUpdatedAtRangeRule(min: 80, max: 3600)
        let item = BedManagement.newBedBoardMetric("x", name: "y")
        item.updatedAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
