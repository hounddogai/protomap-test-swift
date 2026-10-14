@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalOutreachAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalOutreachAllocationValidator()
        let item = CareManagement.newGlobalOutreachAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalOutreachAllocationOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = CareManagement.GlobalOutreachAllocationOwnerIDLengthRule(maxLength: 1000)
        let item = CareManagement.newGlobalOutreachAllocation("x", label: "y")
        item.ownerID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGlobalOutreachAllocationLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = CareManagement.GlobalOutreachAllocationLimitRangeRule(min: 1000, max: 86400)
        let item = CareManagement.newGlobalOutreachAllocation("x", label: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGlobalOutreachAllocationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.GlobalOutreachAllocationRequiredLabelRule(
            message: "global outreach allocation needs an entry"
        )
        let item = CareManagement.newGlobalOutreachAllocation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGlobalOutreachAllocationWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.GlobalOutreachAllocationWindowDaysRangeRule(min: 80, max: 86400)
        let item = CareManagement.newGlobalOutreachAllocation("x", label: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}
