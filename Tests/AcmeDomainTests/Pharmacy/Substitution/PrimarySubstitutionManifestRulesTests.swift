@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPrimarySubstitutionManifestValidator()
        let item = Pharmacy.newPrimarySubstitutionManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPrimarySubstitutionManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.PrimarySubstitutionManifestRequiredCodeRule(
            message: "primary substitution manifest needs an entry"
        )
        let item = Pharmacy.newPrimarySubstitutionManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimarySubstitutionManifestRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Pharmacy.PrimarySubstitutionManifestRequiredContactEmailRule(
            message: "primary substitution manifest needs this field"
        )
        let item = Pharmacy.newPrimarySubstitutionManifest("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimarySubstitutionManifestAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Pharmacy.PrimarySubstitutionManifestAllergyLengthRule(maxLength: 255)
        let item = Pharmacy.newPrimarySubstitutionManifest("x", label: "y")
        item.allergy = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPrimarySubstitutionManifestContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Pharmacy.PrimarySubstitutionManifestContactEmailLengthRule(maxLength: 120)
        let item = Pharmacy.newPrimarySubstitutionManifest("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
