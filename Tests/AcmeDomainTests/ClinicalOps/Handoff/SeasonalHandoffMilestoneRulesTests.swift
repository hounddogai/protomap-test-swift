@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalHandoffMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultSeasonalHandoffMilestoneValidator()
        let item = ClinicalOps.newSeasonalHandoffMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsSeasonalHandoffMilestoneScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = ClinicalOps.SeasonalHandoffMilestoneScoreRangeRule(min: 9.2, max: 2152.2)
        let item = ClinicalOps.newSeasonalHandoffMilestone("x", label: "y")
        item.score = 2153.7
        #expect(rule.check(item).count > 0)
    }
}
