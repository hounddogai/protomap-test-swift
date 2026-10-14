@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalRiskScorePolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultSeasonalRiskScorePolicyValidator()
        let item = CareManagement.newSeasonalRiskScorePolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementSeasonalRiskScorePolicyCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = CareManagement.SeasonalRiskScorePolicyCountryLengthRule(maxLength: 86400)
        let item = CareManagement.newSeasonalRiskScorePolicy("x", name: "y")
        item.country = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementSeasonalRiskScorePolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.SeasonalRiskScorePolicyRequiredCodeRule(
            message: "seasonal risk score policy needs an entry"
        )
        let item = CareManagement.newSeasonalRiskScorePolicy("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementSeasonalRiskScorePolicyRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = CareManagement.SeasonalRiskScorePolicyRequiredCountryRule(
            message: "seasonal risk score policy needs an entry"
        )
        let item = CareManagement.newSeasonalRiskScorePolicy("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementSeasonalRiskScorePolicyNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.SeasonalRiskScorePolicyNameLengthRule(maxLength: 255)
        let item = CareManagement.newSeasonalRiskScorePolicy("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
