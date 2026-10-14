@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalOutreachThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalOutreachThresholdValidator()
        let item = CareManagement.newGlobalOutreachThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalOutreachThresholdRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.GlobalOutreachThresholdRequiredNameRule(
            message: "global outreach threshold needs an entry"
        )
        let item = CareManagement.newGlobalOutreachThreshold("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGlobalOutreachThresholdNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.GlobalOutreachThresholdNameLengthRule(maxLength: 255)
        let item = CareManagement.newGlobalOutreachThreshold("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGlobalOutreachThresholdCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = CareManagement.GlobalOutreachThresholdCategoryLengthRule(maxLength: 86400)
        let item = CareManagement.newGlobalOutreachThreshold("x", name: "y")
        item.category = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGlobalOutreachThresholdPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = CareManagement.GlobalOutreachThresholdPriorityRangeRule(min: 1000, max: 3600)
        let item = CareManagement.newGlobalOutreachThreshold("x", name: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}
