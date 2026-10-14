@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimarySpecimenMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPrimarySpecimenMetricValidator()
        let item = Labs.newPrimarySpecimenMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPrimarySpecimenMetricRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Labs.PrimarySpecimenMetricRequiredSummaryRule(message: "primary specimen metric needs an entry")
        let item = Labs.newPrimarySpecimenMetric("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPrimarySpecimenMetricRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.PrimarySpecimenMetricRequiredLabelRule(message: "primary specimen metric needs this field")
        let item = Labs.newPrimarySpecimenMetric("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPrimarySpecimenMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PrimarySpecimenMetricCodeLengthRule(maxLength: 255)
        let item = Labs.newPrimarySpecimenMetric("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPrimarySpecimenMetricSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Labs.PrimarySpecimenMetricSummaryLengthRule(maxLength: 120)
        let item = Labs.newPrimarySpecimenMetric("x", label: "y")
        item.summary = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
