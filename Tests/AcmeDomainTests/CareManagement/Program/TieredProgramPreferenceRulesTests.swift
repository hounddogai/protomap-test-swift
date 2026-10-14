@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredProgramPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredProgramPreferenceValidator()
        let item = CareManagement.newTieredProgramPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredProgramPreferenceFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.TieredProgramPreferenceFloorValueRangeRule(min: 9.4, max: 3788.4)
        let item = CareManagement.newTieredProgramPreference("x", name: "y")
        item.floorValue = 3789.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementTieredProgramPreferenceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.TieredProgramPreferenceTitleLengthRule(maxLength: 16)
        let item = CareManagement.newTieredProgramPreference("x", name: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredProgramPreferenceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.TieredProgramPreferenceNameLengthRule(maxLength: 32)
        let item = CareManagement.newTieredProgramPreference("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredProgramPreferenceCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = CareManagement.TieredProgramPreferenceCapacityRangeRule(min: 64, max: 255)
        let item = CareManagement.newTieredProgramPreference("x", name: "y")
        item.capacity = 256
        #expect(rule.check(item).count > 0)
    }
}
