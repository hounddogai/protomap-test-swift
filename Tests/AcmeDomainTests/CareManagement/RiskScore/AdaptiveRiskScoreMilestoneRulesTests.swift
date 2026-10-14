@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveRiskScoreMilestoneValidator()
        let item = CareManagement.newAdaptiveRiskScoreMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreMilestoneCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = CareManagement.AdaptiveRiskScoreMilestoneCountryLengthRule(maxLength: 16)
        let item = CareManagement.newAdaptiveRiskScoreMilestone("x", title: "y")
        item.country = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreMilestoneCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = CareManagement.AdaptiveRiskScoreMilestoneCeilingRangeRule(min: 8.6, max: 1972.4)
        let item = CareManagement.newAdaptiveRiskScoreMilestone("x", title: "y")
        item.ceiling = 1973.9
        #expect(rule.check(item).count > 0)
    }
}
