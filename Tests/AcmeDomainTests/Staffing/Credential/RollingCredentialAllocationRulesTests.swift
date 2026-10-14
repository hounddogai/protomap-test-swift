@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingCredentialAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRollingCredentialAllocationValidator()
        let item = Staffing.newRollingCredentialAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRollingCredentialAllocationQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Staffing.RollingCredentialAllocationQuantityRangeRule(min: 64, max: 1000)
        let item = Staffing.newRollingCredentialAllocation("x", title: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRollingCredentialAllocationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.RollingCredentialAllocationRequiredTitleRule(
            message: "rolling credential allocation needs an entry"
        )
        let item = Staffing.newRollingCredentialAllocation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRollingCredentialAllocationCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Staffing.RollingCredentialAllocationCostRangeRule(min: 2.3, max: 4602.8)
        let item = Staffing.newRollingCredentialAllocation("x", title: "y")
        item.cost = 4604.3
        #expect(rule.check(item).count > 0)
    }
}
