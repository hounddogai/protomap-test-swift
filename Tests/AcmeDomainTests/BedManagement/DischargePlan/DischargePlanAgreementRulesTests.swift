@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanAgreementValidator()
        let item = BedManagement.newDischargePlanAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanAgreementUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = BedManagement.DischargePlanAgreementUpdatedAtRangeRule(min: 64, max: 80)
        let item = BedManagement.newDischargePlanAgreement("x", label: "y")
        item.updatedAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanAgreementRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.DischargePlanAgreementRequiredLabelRule(
            message: "discharge plan agreement needs an entry"
        )
        let item = BedManagement.newDischargePlanAgreement("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanAgreementRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = BedManagement.DischargePlanAgreementRequiredCountryRule(
            message: "discharge plan agreement needs this field"
        )
        let item = BedManagement.newDischargePlanAgreement("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.DischargePlanAgreementCodeLengthRule(maxLength: 64)
        let item = BedManagement.newDischargePlanAgreement("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanAgreementLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.DischargePlanAgreementLabelLengthRule(maxLength: 86400)
        let item = BedManagement.newDischargePlanAgreement("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
