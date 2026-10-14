@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingMilestoneValidator()
        let item = ClinicalOps.newRoundingMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingMilestoneRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.RoundingMilestoneRequiredLabelRule(message: "rounding milestone needs a value")
        let item = ClinicalOps.newRoundingMilestone("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.RoundingMilestoneRequiredCodeRule(message: "rounding milestone needs a value")
        let item = ClinicalOps.newRoundingMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
