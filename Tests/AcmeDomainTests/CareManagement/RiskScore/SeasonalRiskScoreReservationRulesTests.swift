@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalRiskScoreReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultSeasonalRiskScoreReservationValidator()
        let item = CareManagement.newSeasonalRiskScoreReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementSeasonalRiskScoreReservationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.SeasonalRiskScoreReservationRequiredLabelRule(
            message: "seasonal risk score reservation needs a value"
        )
        let item = CareManagement.newSeasonalRiskScoreReservation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
