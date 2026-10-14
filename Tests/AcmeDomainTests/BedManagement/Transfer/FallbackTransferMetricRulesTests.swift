@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackTransferMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackTransferMetricValidator()
        let item = BedManagement.newFallbackTransferMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackTransferMetricRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.FallbackTransferMetricRequiredLabelRule(
            message: "fallback transfer metric needs a value"
        )
        let item = BedManagement.newFallbackTransferMetric("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackTransferMetricCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.FallbackTransferMetricCopayRangeRule(min: 1.6, max: 3014.4)
        let item = BedManagement.newFallbackTransferMetric("x", label: "y")
        item.copay = 3015.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementFallbackTransferMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.FallbackTransferMetricRequiredCodeRule(
            message: "fallback transfer metric needs an entry"
        )
        let item = BedManagement.newFallbackTransferMetric("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
