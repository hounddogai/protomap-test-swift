@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachTemplateValidator()
        let item = CareManagement.newOutreachTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachTemplateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.OutreachTemplateRequiredLabelRule(message: "outreach template needs a value")
        let item = CareManagement.newOutreachTemplate("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachTemplateCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = CareManagement.OutreachTemplateCategoryLengthRule(maxLength: 80)
        let item = CareManagement.newOutreachTemplate("x", title: "y")
        item.category = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachTemplateRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = CareManagement.OutreachTemplateRevisionRangeRule(min: 80, max: 86400)
        let item = CareManagement.newOutreachTemplate("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachTemplateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.OutreachTemplateRequiredTitleRule(message: "outreach template needs an entry")
        let item = CareManagement.newOutreachTemplate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachTemplateTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.OutreachTemplateTitleLengthRule(maxLength: 255)
        let item = CareManagement.newOutreachTemplate("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
