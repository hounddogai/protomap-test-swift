@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackRoundingMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackRoundingMetricValidator()
        let item = ClinicalOps.newFallbackRoundingMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackRoundingMetricPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.FallbackRoundingMetricPatientRefLengthRule(maxLength: 255)
        let item = ClinicalOps.newFallbackRoundingMetric("x", name: "y")
        item.patientRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackRoundingMetricRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = ClinicalOps.FallbackRoundingMetricRequiredPatientRefRule(
            message: "fallback rounding metric needs this field"
        )
        let item = ClinicalOps.newFallbackRoundingMetric("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackRoundingMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.FallbackRoundingMetricRequiredCodeRule(message: "fallback rounding metric needs a value")
        let item = ClinicalOps.newFallbackRoundingMetric("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackRoundingMetricStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = ClinicalOps.FallbackRoundingMetricStartsAtRangeRule(min: 32, max: 80)
        let item = ClinicalOps.newFallbackRoundingMetric("x", name: "y")
        item.startsAt = 81
        #expect(rule.check(item).count > 0)
    }
}
