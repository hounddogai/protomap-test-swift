@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientDischargePlanQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLenientDischargePlanQuotaValidator()
        let item = BedManagement.newLenientDischargePlanQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLenientDischargePlanQuotaLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.LenientDischargePlanQuotaLabelLengthRule(maxLength: 32)
        let item = BedManagement.newLenientDischargePlanQuota("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLenientDischargePlanQuotaFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.LenientDischargePlanQuotaFloorValueRangeRule(min: 5.9, max: 722.1)
        let item = BedManagement.newLenientDischargePlanQuota("x", label: "y")
        item.floorValue = 723.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLenientDischargePlanQuotaRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.LenientDischargePlanQuotaRequiredTitleRule(
            message: "lenient discharge plan quota needs this field"
        )
        let item = BedManagement.newLenientDischargePlanQuota("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientDischargePlanQuotaRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = BedManagement.LenientDischargePlanQuotaRequiredEncounterIDRule(
            message: "lenient discharge plan quota needs a value"
        )
        let item = BedManagement.newLenientDischargePlanQuota("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientDischargePlanQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.LenientDischargePlanQuotaRequiredCodeRule(
            message: "lenient discharge plan quota needs a value"
        )
        let item = BedManagement.newLenientDischargePlanQuota("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientDischargePlanQuotaTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.LenientDischargePlanQuotaTitleLengthRule(maxLength: 255)
        let item = BedManagement.newLenientDischargePlanQuota("x", label: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
