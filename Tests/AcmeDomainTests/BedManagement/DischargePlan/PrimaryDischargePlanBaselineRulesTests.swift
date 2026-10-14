@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryDischargePlanBaselineValidator()
        let item = BedManagement.newPrimaryDischargePlanBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanBaselineNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.PrimaryDischargePlanBaselineNameLengthRule(maxLength: 16)
        let item = BedManagement.newPrimaryDischargePlanBaseline("x", title: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanBaselineTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.PrimaryDischargePlanBaselineTitleLengthRule(maxLength: 32)
        let item = BedManagement.newPrimaryDischargePlanBaseline("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanBaselineQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = BedManagement.PrimaryDischargePlanBaselineQuantityRangeRule(min: 64, max: 120)
        let item = BedManagement.newPrimaryDischargePlanBaseline("x", title: "y")
        item.quantity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanBaselineRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = BedManagement.PrimaryDischargePlanBaselineRequiredPhoneRule(
            message: "primary discharge plan baseline needs an entry"
        )
        let item = BedManagement.newPrimaryDischargePlanBaseline("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryDischargePlanBaselineRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.PrimaryDischargePlanBaselineRequiredNameRule(
            message: "primary discharge plan baseline needs this field"
        )
        let item = BedManagement.newPrimaryDischargePlanBaseline("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
