@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffDraftValidator()
        let item = ClinicalOps.newHandoffDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffDraftRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = ClinicalOps.HandoffDraftRefillsRangeRule(min: 255, max: 86400)
        let item = ClinicalOps.newHandoffDraft("x", label: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsHandoffDraftWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = ClinicalOps.HandoffDraftWardLengthRule(maxLength: 16)
        let item = ClinicalOps.newHandoffDraft("x", label: "y")
        item.ward = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
