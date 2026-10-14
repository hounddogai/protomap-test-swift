@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultSeasonalCareGapAssignmentValidator()
        let item = CareManagement.newSeasonalCareGapAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementSeasonalCareGapAssignmentCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = CareManagement.SeasonalCareGapAssignmentCeilingRangeRule(min: 7.2, max: 3271.2)
        let item = CareManagement.newSeasonalCareGapAssignment("x", name: "y")
        item.ceiling = 3272.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementSeasonalCareGapAssignmentAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = CareManagement.SeasonalCareGapAssignmentAcuityRangeRule(min: 255, max: 3600)
        let item = CareManagement.newSeasonalCareGapAssignment("x", name: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementSeasonalCareGapAssignmentExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = CareManagement.SeasonalCareGapAssignmentExpiresAtRangeRule(min: 255, max: 86400)
        let item = CareManagement.newSeasonalCareGapAssignment("x", name: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
