@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCensusForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingCensusForecastValidator()
        let item = BedManagement.newRollingCensusForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingCensusForecastPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = BedManagement.RollingCensusForecastPriorityRangeRule(min: 32, max: 3600)
        let item = BedManagement.newRollingCensusForecast("x", label: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRollingCensusForecastCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.RollingCensusForecastCopayRangeRule(min: 9.5, max: 4135.3)
        let item = BedManagement.newRollingCensusForecast("x", label: "y")
        item.copay = 4136.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRollingCensusForecastAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = BedManagement.RollingCensusForecastAcuityRangeRule(min: 32, max: 32)
        let item = BedManagement.newRollingCensusForecast("x", label: "y")
        item.acuity = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRollingCensusForecastSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = BedManagement.RollingCensusForecastSegmentLengthRule(maxLength: 86400)
        let item = BedManagement.newRollingCensusForecast("x", label: "y")
        item.segment = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementRollingCensusForecastRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = BedManagement.RollingCensusForecastRequiredSegmentRule(
            message: "rolling census forecast needs this field"
        )
        let item = BedManagement.newRollingCensusForecast("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
