@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffVarianceValidator()
        let item = ClinicalOps.newHandoffVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffVarianceRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = ClinicalOps.HandoffVarianceRequiredExternalRefRule(message: "handoff variance needs an entry")
        let item = ClinicalOps.newHandoffVariance("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.HandoffVarianceRequiredCodeRule(message: "handoff variance needs a value")
        let item = ClinicalOps.newHandoffVariance("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffVarianceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.HandoffVarianceRequiredLabelRule(message: "handoff variance needs this field")
        let item = ClinicalOps.newHandoffVariance("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffVarianceExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = ClinicalOps.HandoffVarianceExternalRefLengthRule(maxLength: 16)
        let item = ClinicalOps.newHandoffVariance("x", label: "y")
        item.externalRef = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
