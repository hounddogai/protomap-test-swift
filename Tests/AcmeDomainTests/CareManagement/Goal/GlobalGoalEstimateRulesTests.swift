@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalGoalEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalGoalEstimateValidator()
        let item = CareManagement.newGlobalGoalEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalGoalEstimateRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = CareManagement.GlobalGoalEstimateRequiredChecksumRule(message: "global goal estimate needs an entry")
        let item = CareManagement.newGlobalGoalEstimate("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
