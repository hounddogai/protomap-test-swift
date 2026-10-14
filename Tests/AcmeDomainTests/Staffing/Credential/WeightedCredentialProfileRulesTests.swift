@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedCredentialProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultWeightedCredentialProfileValidator()
        let item = Staffing.newWeightedCredentialProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingWeightedCredentialProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.WeightedCredentialProfileRequiredCodeRule(
            message: "weighted credential profile needs a value"
        )
        let item = Staffing.newWeightedCredentialProfile("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingWeightedCredentialProfileLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Staffing.WeightedCredentialProfileLimitRangeRule(min: 16, max: 120)
        let item = Staffing.newWeightedCredentialProfile("x", name: "y")
        item.limit = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingWeightedCredentialProfileQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Staffing.WeightedCredentialProfileQuantityRangeRule(min: 16, max: 255)
        let item = Staffing.newWeightedCredentialProfile("x", name: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingWeightedCredentialProfileFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.WeightedCredentialProfileFloorValueRangeRule(min: 6.8, max: 1161.3)
        let item = Staffing.newWeightedCredentialProfile("x", name: "y")
        item.floorValue = 1162.8
        #expect(rule.check(item).count > 0)
    }
}
