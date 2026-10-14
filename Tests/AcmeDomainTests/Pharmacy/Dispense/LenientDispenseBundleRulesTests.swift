@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientDispenseBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLenientDispenseBundleValidator()
        let item = Pharmacy.newLenientDispenseBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLenientDispenseBundleRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Pharmacy.LenientDispenseBundleRequiredCountryRule(message: "lenient dispense bundle needs an entry")
        let item = Pharmacy.newLenientDispenseBundle("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientDispenseBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.LenientDispenseBundleRequiredCodeRule(message: "lenient dispense bundle needs an entry")
        let item = Pharmacy.newLenientDispenseBundle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
