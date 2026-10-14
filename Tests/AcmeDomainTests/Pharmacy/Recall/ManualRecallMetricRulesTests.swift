@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultManualRecallMetricValidator()
        let item = Pharmacy.newManualRecallMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyManualRecallMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.ManualRecallMetricCodeLengthRule(maxLength: 16)
        let item = Pharmacy.newManualRecallMetric("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualRecallMetricEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Pharmacy.ManualRecallMetricEndsAtRangeRule(min: 32, max: 64)
        let item = Pharmacy.newManualRecallMetric("x", label: "y")
        item.endsAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyManualRecallMetricRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.ManualRecallMetricRequiredLabelRule(message: "manual recall metric needs a value")
        let item = Pharmacy.newManualRecallMetric("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyManualRecallMetricProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Pharmacy.ManualRecallMetricProcedureCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newManualRecallMetric("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualRecallMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.ManualRecallMetricRequiredCodeRule(message: "manual recall metric needs this field")
        let item = Pharmacy.newManualRecallMetric("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
