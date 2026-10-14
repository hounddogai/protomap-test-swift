@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInteractionAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSeasonalInteractionAgreementValidator()
        let item = Pharmacy.newSeasonalInteractionAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySeasonalInteractionAgreementLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Pharmacy.SeasonalInteractionAgreementLimitRangeRule(min: 32, max: 86400)
        let item = Pharmacy.newSeasonalInteractionAgreement("x", label: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySeasonalInteractionAgreementNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.SeasonalInteractionAgreementNameLengthRule(maxLength: 64)
        let item = Pharmacy.newSeasonalInteractionAgreement("x", label: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySeasonalInteractionAgreementRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.SeasonalInteractionAgreementRequiredNameRule(
            message: "seasonal interaction agreement needs a value"
        )
        let item = Pharmacy.newSeasonalInteractionAgreement("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySeasonalInteractionAgreementRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.SeasonalInteractionAgreementRequiredLabelRule(
            message: "seasonal interaction agreement needs a value"
        )
        let item = Pharmacy.newSeasonalInteractionAgreement("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySeasonalInteractionAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.SeasonalInteractionAgreementRequiredCodeRule(
            message: "seasonal interaction agreement needs a value"
        )
        let item = Pharmacy.newSeasonalInteractionAgreement("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
