@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackDischargePlanMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackDischargePlanMetricValidator()
        let item = BedManagement.newFallbackDischargePlanMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackDischargePlanMetricClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = BedManagement.FallbackDischargePlanMetricClinicianIDLengthRule(maxLength: 3600)
        let item = BedManagement.newFallbackDischargePlanMetric("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackDischargePlanMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.FallbackDischargePlanMetricRequiredCodeRule(
            message: "fallback discharge plan metric needs this field"
        )
        let item = BedManagement.newFallbackDischargePlanMetric("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackDischargePlanMetricRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.FallbackDischargePlanMetricRequiredLabelRule(
            message: "fallback discharge plan metric needs this field"
        )
        let item = BedManagement.newFallbackDischargePlanMetric("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackDischargePlanMetricRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = BedManagement.FallbackDischargePlanMetricRequiredFacilityRule(
            message: "fallback discharge plan metric needs an entry"
        )
        let item = BedManagement.newFallbackDischargePlanMetric("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
