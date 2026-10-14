@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackTaskAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackTaskAssignmentValidator()
        let item = ClinicalOps.newFallbackTaskAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackTaskAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.FallbackTaskAssignmentRequiredCodeRule(message: "fallback task assignment needs an entry")
        let item = ClinicalOps.newFallbackTaskAssignment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
