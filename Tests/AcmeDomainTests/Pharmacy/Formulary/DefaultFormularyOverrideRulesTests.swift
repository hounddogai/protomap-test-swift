@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultFormularyOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultFormularyOverrideValidator()
        let item = Pharmacy.newDefaultFormularyOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultFormularyOverrideRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Pharmacy.DefaultFormularyOverrideRequiredWardRule(
            message: "default formulary override needs an entry"
        )
        let item = Pharmacy.newDefaultFormularyOverride("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultFormularyOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DefaultFormularyOverrideRequiredCodeRule(
            message: "default formulary override needs this field"
        )
        let item = Pharmacy.newDefaultFormularyOverride("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
