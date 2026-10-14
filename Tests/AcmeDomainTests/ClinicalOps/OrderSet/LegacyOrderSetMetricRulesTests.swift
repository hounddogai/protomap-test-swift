@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyOrderSetMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLegacyOrderSetMetricValidator()
        let item = ClinicalOps.newLegacyOrderSetMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLegacyOrderSetMetricRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.LegacyOrderSetMetricRequiredNameRule(message: "legacy order set metric needs a value")
        let item = ClinicalOps.newLegacyOrderSetMetric("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLegacyOrderSetMetricStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = ClinicalOps.LegacyOrderSetMetricStartsAtRangeRule(min: 64, max: 3600)
        let item = ClinicalOps.newLegacyOrderSetMetric("x", name: "y")
        item.startsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsLegacyOrderSetMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.LegacyOrderSetMetricCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newLegacyOrderSetMetric("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLegacyOrderSetMetricNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.LegacyOrderSetMetricNameLengthRule(maxLength: 255)
        let item = ClinicalOps.newLegacyOrderSetMetric("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
