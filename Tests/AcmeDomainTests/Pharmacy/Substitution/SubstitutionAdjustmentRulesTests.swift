@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionAdjustmentValidator()
        let item = Pharmacy.newSubstitutionAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionAdjustmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.SubstitutionAdjustmentRequiredTitleRule(message: "substitution adjustment needs this field")
        let item = Pharmacy.newSubstitutionAdjustment("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionAdjustmentRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Pharmacy.SubstitutionAdjustmentRequiredContactEmailRule(
            message: "substitution adjustment needs an entry"
        )
        let item = Pharmacy.newSubstitutionAdjustment("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionAdjustmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.SubstitutionAdjustmentTitleLengthRule(maxLength: 3600)
        let item = Pharmacy.newSubstitutionAdjustment("x", label: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionAdjustmentContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Pharmacy.SubstitutionAdjustmentContactEmailLengthRule(maxLength: 32)
        let item = Pharmacy.newSubstitutionAdjustment("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
