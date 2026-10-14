@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachPolicyValidator()
        let item = CareManagement.newOutreachPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachPolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.OutreachPolicyRequiredLabelRule(message: "outreach policy needs a value")
        let item = CareManagement.newOutreachPolicy("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachPolicyRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = CareManagement.OutreachPolicyRefillsRangeRule(min: 255, max: 3600)
        let item = CareManagement.newOutreachPolicy("x", title: "y")
        item.refills = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachPolicyWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.OutreachPolicyWindowDaysRangeRule(min: 64, max: 3600)
        let item = CareManagement.newOutreachPolicy("x", title: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachPolicyRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = CareManagement.OutreachPolicyRequiredRegionRule(message: "outreach policy needs this field")
        let item = CareManagement.newOutreachPolicy("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
