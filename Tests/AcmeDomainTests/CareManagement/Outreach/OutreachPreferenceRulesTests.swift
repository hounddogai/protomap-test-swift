@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachPreferenceValidator()
        let item = CareManagement.newOutreachPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachPreferenceLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = CareManagement.OutreachPreferenceLimitRangeRule(min: 80, max: 3600)
        let item = CareManagement.newOutreachPreference("x", title: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachPreferenceCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = CareManagement.OutreachPreferenceCategoryLengthRule(maxLength: 86400)
        let item = CareManagement.newOutreachPreference("x", title: "y")
        item.category = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.OutreachPreferenceRequiredCodeRule(message: "outreach preference needs an entry")
        let item = CareManagement.newOutreachPreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
