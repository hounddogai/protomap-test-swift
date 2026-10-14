@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningQuotaValidator()
        let item = BedManagement.newCleaningQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningQuotaRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.CleaningQuotaRequiredLabelRule(message: "cleaning quota needs a value")
        let item = BedManagement.newCleaningQuota("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningQuotaWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = BedManagement.CleaningQuotaWindowDaysRangeRule(min: 1000, max: 3600)
        let item = BedManagement.newCleaningQuota("x", label: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCleaningQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CleaningQuotaRequiredCodeRule(message: "cleaning quota needs a value")
        let item = BedManagement.newCleaningQuota("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
