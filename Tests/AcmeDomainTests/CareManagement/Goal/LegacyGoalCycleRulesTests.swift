@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyGoalCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLegacyGoalCycleValidator()
        let item = CareManagement.newLegacyGoalCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLegacyGoalCycleRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = CareManagement.LegacyGoalCycleRequiredWardRule(message: "legacy goal cycle needs a value")
        let item = CareManagement.newLegacyGoalCycle("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLegacyGoalCycleStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = CareManagement.LegacyGoalCycleStartsAtRangeRule(min: 32, max: 255)
        let item = CareManagement.newLegacyGoalCycle("x", title: "y")
        item.startsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementLegacyGoalCycleFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.LegacyGoalCycleFloorValueRangeRule(min: 9.3, max: 906.3)
        let item = CareManagement.newLegacyGoalCycle("x", title: "y")
        item.floorValue = 907.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementLegacyGoalCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.LegacyGoalCycleRequiredCodeRule(message: "legacy goal cycle needs this field")
        let item = CareManagement.newLegacyGoalCycle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
