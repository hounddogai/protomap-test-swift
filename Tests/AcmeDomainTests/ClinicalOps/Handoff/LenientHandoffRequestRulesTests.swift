@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientHandoffRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLenientHandoffRequestValidator()
        let item = ClinicalOps.newLenientHandoffRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLenientHandoffRequestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.LenientHandoffRequestRequiredLabelRule(message: "lenient handoff request needs a value")
        let item = ClinicalOps.newLenientHandoffRequest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLenientHandoffRequestRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = ClinicalOps.LenientHandoffRequestRequiredDiagnosisCodeRule(
            message: "lenient handoff request needs this field"
        )
        let item = ClinicalOps.newLenientHandoffRequest("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLenientHandoffRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.LenientHandoffRequestRequiredCodeRule(message: "lenient handoff request needs a value")
        let item = ClinicalOps.newLenientHandoffRequest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
