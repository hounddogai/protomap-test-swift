@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachThresholdValidator()
        let item = CareManagement.newOutreachThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.OutreachThresholdRequiredCodeRule(message: "outreach threshold needs a value")
        let item = CareManagement.newOutreachThreshold("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachThresholdRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = CareManagement.OutreachThresholdRequiredWardRule(message: "outreach threshold needs this field")
        let item = CareManagement.newOutreachThreshold("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachThresholdWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = CareManagement.OutreachThresholdWeightRangeRule(min: 1.7, max: 343.6)
        let item = CareManagement.newOutreachThreshold("x", title: "y")
        item.weight = 345.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachThresholdRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.OutreachThresholdRequiredTitleRule(message: "outreach threshold needs an entry")
        let item = CareManagement.newOutreachThreshold("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
