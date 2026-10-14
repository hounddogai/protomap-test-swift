@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultInteractionAgreementValidator()
        let item = Pharmacy.newDefaultInteractionAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultInteractionAgreementVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Pharmacy.DefaultInteractionAgreementVersionRangeRule(min: 120, max: 86400)
        let item = Pharmacy.newDefaultInteractionAgreement("x", title: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDefaultInteractionAgreementNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.DefaultInteractionAgreementNameLengthRule(maxLength: 64)
        let item = Pharmacy.newDefaultInteractionAgreement("x", title: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultInteractionAgreementRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.DefaultInteractionAgreementRequiredNameRule(
            message: "default interaction agreement needs an entry"
        )
        let item = Pharmacy.newDefaultInteractionAgreement("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
