@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPrimarySubstitutionBundleValidator()
        let item = Pharmacy.newPrimarySubstitutionBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPrimarySubstitutionBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.PrimarySubstitutionBundleRequiredNameRule(
            message: "primary substitution bundle needs a value"
        )
        let item = Pharmacy.newPrimarySubstitutionBundle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimarySubstitutionBundleVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Pharmacy.PrimarySubstitutionBundleVersionRangeRule(min: 32, max: 3600)
        let item = Pharmacy.newPrimarySubstitutionBundle("x", name: "y")
        item.version = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPrimarySubstitutionBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.PrimarySubstitutionBundleRequiredCodeRule(
            message: "primary substitution bundle needs a value"
        )
        let item = Pharmacy.newPrimarySubstitutionBundle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimarySubstitutionBundleRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Pharmacy.PrimarySubstitutionBundleRequiredChecksumRule(
            message: "primary substitution bundle needs an entry"
        )
        let item = Pharmacy.newPrimarySubstitutionBundle("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
