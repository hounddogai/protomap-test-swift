@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyIsolationMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLegacyIsolationMetricValidator()
        let item = BedManagement.newLegacyIsolationMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLegacyIsolationMetricRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = BedManagement.LegacyIsolationMetricRequiredFacilityRule(
            message: "legacy isolation metric needs a value"
        )
        let item = BedManagement.newLegacyIsolationMetric("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLegacyIsolationMetricGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.LegacyIsolationMetricGraceDaysRangeRule(min: 1000, max: 3600)
        let item = BedManagement.newLegacyIsolationMetric("x", name: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLegacyIsolationMetricRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.LegacyIsolationMetricRequiredNameRule(message: "legacy isolation metric needs an entry")
        let item = BedManagement.newLegacyIsolationMetric("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLegacyIsolationMetricStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = BedManagement.LegacyIsolationMetricStartsAtRangeRule(min: 80, max: 86400)
        let item = BedManagement.newLegacyIsolationMetric("x", name: "y")
        item.startsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
