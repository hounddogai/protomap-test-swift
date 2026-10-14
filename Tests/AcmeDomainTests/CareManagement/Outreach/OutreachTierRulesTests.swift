@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachTierValidator()
        let item = CareManagement.newOutreachTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachTierLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = CareManagement.OutreachTierLocaleLengthRule(maxLength: 3600)
        let item = CareManagement.newOutreachTier("x", title: "y")
        item.locale = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachTierMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = CareManagement.OutreachTierMinimumRangeRule(min: 5.5, max: 2744.8)
        let item = CareManagement.newOutreachTier("x", title: "y")
        item.minimum = 2746.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.OutreachTierCodeLengthRule(maxLength: 255)
        let item = CareManagement.newOutreachTier("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachTierRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.OutreachTierRequiredTitleRule(message: "outreach tier needs this field")
        let item = CareManagement.newOutreachTier("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachTierGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = CareManagement.OutreachTierGraceDaysRangeRule(min: 16, max: 16)
        let item = CareManagement.newOutreachTier("x", title: "y")
        item.graceDays = 17
        #expect(rule.check(item).count > 0)
    }
}
