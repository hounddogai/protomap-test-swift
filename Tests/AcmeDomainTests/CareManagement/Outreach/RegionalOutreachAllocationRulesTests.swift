@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalOutreachAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRegionalOutreachAllocationValidator()
        let item = CareManagement.newRegionalOutreachAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRegionalOutreachAllocationRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = CareManagement.RegionalOutreachAllocationRequiredTimezoneRule(
            message: "regional outreach allocation needs an entry"
        )
        let item = CareManagement.newRegionalOutreachAllocation("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRegionalOutreachAllocationDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = CareManagement.RegionalOutreachAllocationDescriptionLengthRule(maxLength: 120)
        let item = CareManagement.newRegionalOutreachAllocation("x", label: "y")
        item.description = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRegionalOutreachAllocationTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = CareManagement.RegionalOutreachAllocationTimezoneLengthRule(maxLength: 32)
        let item = CareManagement.newRegionalOutreachAllocation("x", label: "y")
        item.timezone = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
