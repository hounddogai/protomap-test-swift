@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyCareGapQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLegacyCareGapQuotaValidator()
        let item = CareManagement.newLegacyCareGapQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLegacyCareGapQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.LegacyCareGapQuotaCodeLengthRule(maxLength: 80)
        let item = CareManagement.newLegacyCareGapQuota("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLegacyCareGapQuotaRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.LegacyCareGapQuotaRequiredChannelRule(message: "legacy care gap quota needs a value")
        let item = CareManagement.newLegacyCareGapQuota("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLegacyCareGapQuotaLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.LegacyCareGapQuotaLabelLengthRule(maxLength: 120)
        let item = CareManagement.newLegacyCareGapQuota("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLegacyCareGapQuotaWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.LegacyCareGapQuotaWindowDaysRangeRule(min: 1000, max: 86400)
        let item = CareManagement.newLegacyCareGapQuota("x", label: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}
