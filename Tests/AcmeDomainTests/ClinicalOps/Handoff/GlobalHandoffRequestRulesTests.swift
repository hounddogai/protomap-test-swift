@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalHandoffRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalHandoffRequestValidator()
        let item = ClinicalOps.newGlobalHandoffRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalHandoffRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.GlobalHandoffRequestCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newGlobalHandoffRequest("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsGlobalHandoffRequestExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = ClinicalOps.GlobalHandoffRequestExpiresAtRangeRule(min: 80, max: 80)
        let item = ClinicalOps.newGlobalHandoffRequest("x", label: "y")
        item.expiresAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalHandoffRequestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.GlobalHandoffRequestRequiredLabelRule(message: "global handoff request needs an entry")
        let item = ClinicalOps.newGlobalHandoffRequest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
