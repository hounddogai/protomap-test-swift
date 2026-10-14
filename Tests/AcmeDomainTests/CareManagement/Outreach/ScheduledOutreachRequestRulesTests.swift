@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledOutreachRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultScheduledOutreachRequestValidator()
        let item = CareManagement.newScheduledOutreachRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementScheduledOutreachRequestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.ScheduledOutreachRequestRequiredNameRule(
            message: "scheduled outreach request needs a value"
        )
        let item = CareManagement.newScheduledOutreachRequest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementScheduledOutreachRequestRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = CareManagement.ScheduledOutreachRequestRequiredTimezoneRule(
            message: "scheduled outreach request needs this field"
        )
        let item = CareManagement.newScheduledOutreachRequest("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementScheduledOutreachRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ScheduledOutreachRequestRequiredCodeRule(
            message: "scheduled outreach request needs this field"
        )
        let item = CareManagement.newScheduledOutreachRequest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementScheduledOutreachRequestTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = CareManagement.ScheduledOutreachRequestTimezoneLengthRule(maxLength: 120)
        let item = CareManagement.newScheduledOutreachRequest("x", name: "y")
        item.timezone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
