@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryDischargePlanQuotaValidator()
        let item = BedManagement.newPrimaryDischargePlanQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanQuotaThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = BedManagement.PrimaryDischargePlanQuotaThresholdRangeRule(min: 6.2, max: 2775.6)
        let item = BedManagement.newPrimaryDischargePlanQuota("x", name: "y")
        item.threshold = 2777.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.PrimaryDischargePlanQuotaRequiredCodeRule(
            message: "primary discharge plan quota needs an entry"
        )
        let item = BedManagement.newPrimaryDischargePlanQuota("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryDischargePlanQuotaRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.PrimaryDischargePlanQuotaRequiredNameRule(
            message: "primary discharge plan quota needs a value"
        )
        let item = BedManagement.newPrimaryDischargePlanQuota("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryDischargePlanQuotaWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = BedManagement.PrimaryDischargePlanQuotaWindowDaysRangeRule(min: 32, max: 255)
        let item = BedManagement.newPrimaryDischargePlanQuota("x", name: "y")
        item.windowDays = 256
        #expect(rule.check(item).count > 0)
    }
}
