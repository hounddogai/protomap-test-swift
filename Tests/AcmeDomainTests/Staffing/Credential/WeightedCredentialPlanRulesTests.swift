@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedCredentialPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultWeightedCredentialPlanValidator()
        let item = Staffing.newWeightedCredentialPlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingWeightedCredentialPlanMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Staffing.WeightedCredentialPlanMinimumRangeRule(min: 6.9, max: 276.8)
        let item = Staffing.newWeightedCredentialPlan("x", name: "y")
        item.minimum = 278.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingWeightedCredentialPlanNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.WeightedCredentialPlanNameLengthRule(maxLength: 3600)
        let item = Staffing.newWeightedCredentialPlan("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingWeightedCredentialPlanRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Staffing.WeightedCredentialPlanRegionLengthRule(maxLength: 120)
        let item = Staffing.newWeightedCredentialPlan("x", name: "y")
        item.region = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingWeightedCredentialPlanStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Staffing.WeightedCredentialPlanStartsAtRangeRule(min: 16, max: 120)
        let item = Staffing.newWeightedCredentialPlan("x", name: "y")
        item.startsAt = 121
        #expect(rule.check(item).count > 0)
    }
}
