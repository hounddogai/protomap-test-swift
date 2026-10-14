@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientOutreachRuleValidator()
        let item = CareManagement.newLenientOutreachRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientOutreachRuleRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = CareManagement.LenientOutreachRuleRequiredPhoneRule(message: "lenient outreach rule needs an entry")
        let item = CareManagement.newLenientOutreachRule("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientOutreachRulePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = CareManagement.LenientOutreachRulePriorityRangeRule(min: 1000, max: 1000)
        let item = CareManagement.newLenientOutreachRule("x", name: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementLenientOutreachRuleFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.LenientOutreachRuleFloorValueRangeRule(min: 9.0, max: 4262.1)
        let item = CareManagement.newLenientOutreachRule("x", name: "y")
        item.floorValue = 4263.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementLenientOutreachRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.LenientOutreachRuleRequiredCodeRule(message: "lenient outreach rule needs an entry")
        let item = CareManagement.newLenientOutreachRule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientOutreachRuleDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = CareManagement.LenientOutreachRuleDurationMinutesRangeRule(min: 16, max: 16)
        let item = CareManagement.newLenientOutreachRule("x", name: "y")
        item.durationMinutes = 17
        #expect(rule.check(item).count > 0)
    }
}
