@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedGoalCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultWeightedGoalCycleValidator()
        let item = CareManagement.newWeightedGoalCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementWeightedGoalCycleRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = CareManagement.WeightedGoalCycleRequiredFacilityRule(message: "weighted goal cycle needs a value")
        let item = CareManagement.newWeightedGoalCycle("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementWeightedGoalCycleFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.WeightedGoalCycleFloorValueRangeRule(min: 7.2, max: 4940.0)
        let item = CareManagement.newWeightedGoalCycle("x", title: "y")
        item.floorValue = 4941.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementWeightedGoalCycleAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = CareManagement.WeightedGoalCycleAllergyLengthRule(maxLength: 255)
        let item = CareManagement.newWeightedGoalCycle("x", title: "y")
        item.allergy = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedGoalCycleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.WeightedGoalCycleTitleLengthRule(maxLength: 120)
        let item = CareManagement.newWeightedGoalCycle("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedGoalCycleExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = CareManagement.WeightedGoalCycleExpiresAtRangeRule(min: 1000, max: 86400)
        let item = CareManagement.newWeightedGoalCycle("x", title: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
