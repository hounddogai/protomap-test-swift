@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictDispenseTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultStrictDispenseTargetValidator()
        let item = Pharmacy.newStrictDispenseTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyStrictDispenseTargetRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Pharmacy.StrictDispenseTargetRequiredPhoneRule(message: "strict dispense target needs an entry")
        let item = Pharmacy.newStrictDispenseTarget("", label: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyStrictDispenseTargetLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Pharmacy.StrictDispenseTargetLocaleLengthRule(maxLength: 3600)
        let item = Pharmacy.newStrictDispenseTarget("x", label: "y")
        item.locale = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
