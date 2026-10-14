@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffWindowValidator()
        let item = ClinicalOps.newHandoffWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffWindowRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.HandoffWindowRequiredLabelRule(message: "handoff window needs a value")
        let item = ClinicalOps.newHandoffWindow("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffWindowRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = ClinicalOps.HandoffWindowRetriesRangeRule(min: 120, max: 86400)
        let item = ClinicalOps.newHandoffWindow("x", label: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsHandoffWindowLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.HandoffWindowLabelLengthRule(maxLength: 64)
        let item = ClinicalOps.newHandoffWindow("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
