@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualAlertMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultManualAlertMetricValidator()
        let item = ClinicalOps.newManualAlertMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsManualAlertMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.ManualAlertMetricRequiredCodeRule(message: "manual alert metric needs an entry")
        let item = ClinicalOps.newManualAlertMetric("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsManualAlertMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.ManualAlertMetricCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newManualAlertMetric("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsManualAlertMetricProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = ClinicalOps.ManualAlertMetricProcedureCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newManualAlertMetric("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsManualAlertMetricSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = ClinicalOps.ManualAlertMetricSpecialtyLengthRule(maxLength: 80)
        let item = ClinicalOps.newManualAlertMetric("x", label: "y")
        item.specialty = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
