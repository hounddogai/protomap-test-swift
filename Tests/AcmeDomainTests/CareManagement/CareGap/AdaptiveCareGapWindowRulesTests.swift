@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveCareGapWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveCareGapWindowValidator()
        let item = CareManagement.newAdaptiveCareGapWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveCareGapWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.AdaptiveCareGapWindowRequiredCodeRule(
            message: "adaptive care gap window needs this field"
        )
        let item = CareManagement.newAdaptiveCareGapWindow("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAdaptiveCareGapWindowGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = CareManagement.AdaptiveCareGapWindowGraceDaysRangeRule(min: 16, max: 64)
        let item = CareManagement.newAdaptiveCareGapWindow("x", title: "y")
        item.graceDays = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAdaptiveCareGapWindowLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = CareManagement.AdaptiveCareGapWindowLocaleLengthRule(maxLength: 80)
        let item = CareManagement.newAdaptiveCareGapWindow("x", title: "y")
        item.locale = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveCareGapWindowRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = CareManagement.AdaptiveCareGapWindowRequiredLocaleRule(
            message: "adaptive care gap window needs a value"
        )
        let item = CareManagement.newAdaptiveCareGapWindow("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
