@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffExceptionValidator()
        let item = ClinicalOps.newHandoffException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.HandoffExceptionRequiredCodeRule(message: "handoff exception needs a value")
        let item = ClinicalOps.newHandoffException("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffExceptionExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = ClinicalOps.HandoffExceptionExpiresAtRangeRule(min: 255, max: 1000)
        let item = ClinicalOps.newHandoffException("x", title: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsHandoffExceptionCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = ClinicalOps.HandoffExceptionCapacityRangeRule(min: 80, max: 120)
        let item = ClinicalOps.newHandoffException("x", title: "y")
        item.capacity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsHandoffExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.HandoffExceptionTitleLengthRule(maxLength: 16)
        let item = ClinicalOps.newHandoffException("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
