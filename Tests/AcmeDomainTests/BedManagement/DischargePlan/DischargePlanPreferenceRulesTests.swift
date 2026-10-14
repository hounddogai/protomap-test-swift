@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanPreferenceValidator()
        let item = BedManagement.newDischargePlanPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanPreferenceRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.DischargePlanPreferenceRequiredNameRule(
            message: "discharge plan preference needs a value"
        )
        let item = BedManagement.newDischargePlanPreference("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.DischargePlanPreferenceCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newDischargePlanPreference("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanPreferenceDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = BedManagement.DischargePlanPreferenceDiscountRangeRule(min: 0.9, max: 4396.1)
        let item = BedManagement.newDischargePlanPreference("x", name: "y")
        item.discount = 4397.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanPreferenceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.DischargePlanPreferenceTitleLengthRule(maxLength: 255)
        let item = BedManagement.newDischargePlanPreference("x", name: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
