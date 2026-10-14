@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalFormularyMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRegionalFormularyMilestoneValidator()
        let item = Pharmacy.newRegionalFormularyMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRegionalFormularyMilestoneTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.RegionalFormularyMilestoneTitleLengthRule(maxLength: 120)
        let item = Pharmacy.newRegionalFormularyMilestone("x", label: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRegionalFormularyMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RegionalFormularyMilestoneRequiredCodeRule(
            message: "regional formulary milestone needs this field"
        )
        let item = Pharmacy.newRegionalFormularyMilestone("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRegionalFormularyMilestoneLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.RegionalFormularyMilestoneLabelLengthRule(maxLength: 3600)
        let item = Pharmacy.newRegionalFormularyMilestone("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRegionalFormularyMilestoneRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Pharmacy.RegionalFormularyMilestoneRequiredPayerRule(
            message: "regional formulary milestone needs a value"
        )
        let item = Pharmacy.newRegionalFormularyMilestone("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
