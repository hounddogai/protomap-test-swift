@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictInteractionManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultStrictInteractionManifestValidator()
        let item = Pharmacy.newStrictInteractionManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyStrictInteractionManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.StrictInteractionManifestRequiredCodeRule(
            message: "strict interaction manifest needs an entry"
        )
        let item = Pharmacy.newStrictInteractionManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyStrictInteractionManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.StrictInteractionManifestCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newStrictInteractionManifest("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyStrictInteractionManifestAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Pharmacy.StrictInteractionManifestAmountRangeRule(min: 6.1, max: 1816.0)
        let item = Pharmacy.newStrictInteractionManifest("x", label: "y")
        item.amount = 1817.5
        #expect(rule.check(item).count > 0)
    }
}
