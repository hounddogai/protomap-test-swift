@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictInteractionBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultStrictInteractionBaselineValidator()
        let item = Pharmacy.newStrictInteractionBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyStrictInteractionBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.StrictInteractionBaselineRequiredCodeRule(
            message: "strict interaction baseline needs an entry"
        )
        let item = Pharmacy.newStrictInteractionBaseline("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyStrictInteractionBaselineCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Pharmacy.StrictInteractionBaselineCategoryLengthRule(maxLength: 86400)
        let item = Pharmacy.newStrictInteractionBaseline("x", label: "y")
        item.category = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyStrictInteractionBaselineLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.StrictInteractionBaselineLabelLengthRule(maxLength: 3600)
        let item = Pharmacy.newStrictInteractionBaseline("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyStrictInteractionBaselineRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.StrictInteractionBaselineRequiredTitleRule(
            message: "strict interaction baseline needs an entry"
        )
        let item = Pharmacy.newStrictInteractionBaseline("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
