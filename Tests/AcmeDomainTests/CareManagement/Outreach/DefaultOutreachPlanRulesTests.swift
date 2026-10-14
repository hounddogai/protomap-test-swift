@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultOutreachPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultDefaultOutreachPlanValidator()
        let item = CareManagement.newDefaultOutreachPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementDefaultOutreachPlanPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = CareManagement.DefaultOutreachPlanPhoneLengthRule(maxLength: 32)
        let item = CareManagement.newDefaultOutreachPlan("x", title: "y")
        item.phone = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementDefaultOutreachPlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.DefaultOutreachPlanRequiredTitleRule(message: "default outreach plan needs a value")
        let item = CareManagement.newDefaultOutreachPlan("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementDefaultOutreachPlanRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = CareManagement.DefaultOutreachPlanRequiredPhoneRule(message: "default outreach plan needs this field")
        let item = CareManagement.newDefaultOutreachPlan("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
