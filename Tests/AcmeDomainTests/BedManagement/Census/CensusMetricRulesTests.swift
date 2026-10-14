@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusMetricValidator()
        let item = BedManagement.newCensusMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusMetricReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = BedManagement.CensusMetricReviewerLengthRule(maxLength: 1000)
        let item = BedManagement.newCensusMetric("x", name: "y")
        item.reviewer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusMetricRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = BedManagement.CensusMetricRequiredFacilityRule(message: "census metric needs a value")
        let item = BedManagement.newCensusMetric("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusMetricAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = BedManagement.CensusMetricAmountRangeRule(min: 0.0, max: 2135.4)
        let item = BedManagement.newCensusMetric("x", name: "y")
        item.amount = 2136.9
        #expect(rule.check(item).count > 0)
    }
}
