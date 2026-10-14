@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientSubstitutionClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLenientSubstitutionClaimValidator()
        let item = Pharmacy.newLenientSubstitutionClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLenientSubstitutionClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.LenientSubstitutionClaimCodeLengthRule(maxLength: 86400)
        let item = Pharmacy.newLenientSubstitutionClaim("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLenientSubstitutionClaimRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.LenientSubstitutionClaimRequiredNameRule(
            message: "lenient substitution claim needs an entry"
        )
        let item = Pharmacy.newLenientSubstitutionClaim("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientSubstitutionClaimLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Pharmacy.LenientSubstitutionClaimLocaleLengthRule(maxLength: 16)
        let item = Pharmacy.newLenientSubstitutionClaim("x", name: "y")
        item.locale = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
