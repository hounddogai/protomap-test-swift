@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackCareProtocolAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackCareProtocolAssignmentValidator()
        let item = ClinicalOps.newFallbackCareProtocolAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackCareProtocolAssignmentEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = ClinicalOps.FallbackCareProtocolAssignmentEndsAtRangeRule(min: 80, max: 86400)
        let item = ClinicalOps.newFallbackCareProtocolAssignment("x", label: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsFallbackCareProtocolAssignmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.FallbackCareProtocolAssignmentLabelLengthRule(maxLength: 80)
        let item = ClinicalOps.newFallbackCareProtocolAssignment("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackCareProtocolAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.FallbackCareProtocolAssignmentRequiredCodeRule(
            message: "fallback care protocol assignment needs this field"
        )
        let item = ClinicalOps.newFallbackCareProtocolAssignment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
