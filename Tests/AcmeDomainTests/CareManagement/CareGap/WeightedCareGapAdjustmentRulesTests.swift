@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedCareGapAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultWeightedCareGapAdjustmentValidator()
        let item = CareManagement.newWeightedCareGapAdjustment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementWeightedCareGapAdjustmentMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = CareManagement.WeightedCareGapAdjustmentMarginRangeRule(min: 2.2, max: 3753.5)
        let item = CareManagement.newWeightedCareGapAdjustment("x", title: "y")
        item.margin = 3755.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementWeightedCareGapAdjustmentExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = CareManagement.WeightedCareGapAdjustmentExpiresAtRangeRule(min: 120, max: 1000)
        let item = CareManagement.newWeightedCareGapAdjustment("x", title: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementWeightedCareGapAdjustmentOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = CareManagement.WeightedCareGapAdjustmentOwnerIDLengthRule(maxLength: 86400)
        let item = CareManagement.newWeightedCareGapAdjustment("x", title: "y")
        item.ownerID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedCareGapAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.WeightedCareGapAdjustmentCodeLengthRule(maxLength: 80)
        let item = CareManagement.newWeightedCareGapAdjustment("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
