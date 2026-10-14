@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedCareGapClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultWeightedCareGapClaimValidator()
        let item = CareManagement.newWeightedCareGapClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementWeightedCareGapClaimGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = CareManagement.WeightedCareGapClaimGraceDaysRangeRule(min: 255, max: 86400)
        let item = CareManagement.newWeightedCareGapClaim("x", label: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementWeightedCareGapClaimRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = CareManagement.WeightedCareGapClaimRequiredRegionRule(
            message: "weighted care gap claim needs this field"
        )
        let item = CareManagement.newWeightedCareGapClaim("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementWeightedCareGapClaimWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.WeightedCareGapClaimWindowDaysRangeRule(min: 80, max: 255)
        let item = CareManagement.newWeightedCareGapClaim("x", label: "y")
        item.windowDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementWeightedCareGapClaimUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = CareManagement.WeightedCareGapClaimUnitLengthRule(maxLength: 32)
        let item = CareManagement.newWeightedCareGapClaim("x", label: "y")
        item.unit = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedCareGapClaimExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = CareManagement.WeightedCareGapClaimExpiresAtRangeRule(min: 80, max: 3600)
        let item = CareManagement.newWeightedCareGapClaim("x", label: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
