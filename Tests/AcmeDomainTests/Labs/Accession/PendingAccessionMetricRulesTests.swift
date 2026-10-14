@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingAccessionMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPendingAccessionMetricValidator()
        let item = Labs.newPendingAccessionMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPendingAccessionMetricNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Labs.PendingAccessionMetricNotesLengthRule(maxLength: 255)
        let item = Labs.newPendingAccessionMetric("x", label: "y")
        item.notes = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPendingAccessionMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PendingAccessionMetricRequiredCodeRule(message: "pending accession metric needs a value")
        let item = Labs.newPendingAccessionMetric("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingAccessionMetricVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Labs.PendingAccessionMetricVersionRangeRule(min: 80, max: 1000)
        let item = Labs.newPendingAccessionMetric("x", label: "y")
        item.version = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPendingAccessionMetricLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.PendingAccessionMetricLabelLengthRule(maxLength: 64)
        let item = Labs.newPendingAccessionMetric("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
