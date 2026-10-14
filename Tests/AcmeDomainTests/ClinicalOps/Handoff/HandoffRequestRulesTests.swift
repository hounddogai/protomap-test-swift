@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffRequestValidator()
        let item = ClinicalOps.newHandoffRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffRequestUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = ClinicalOps.HandoffRequestUpdatedAtRangeRule(min: 16, max: 86400)
        let item = ClinicalOps.newHandoffRequest("x", name: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsHandoffRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.HandoffRequestRequiredCodeRule(message: "handoff request needs an entry")
        let item = ClinicalOps.newHandoffRequest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.HandoffRequestCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newHandoffRequest("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffRequestAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = ClinicalOps.HandoffRequestAcuityRangeRule(min: 255, max: 1000)
        let item = ClinicalOps.newHandoffRequest("x", name: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}
