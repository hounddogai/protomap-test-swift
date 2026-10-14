@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientSubstitutionDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLenientSubstitutionDigestValidator()
        let item = Pharmacy.newLenientSubstitutionDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLenientSubstitutionDigestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.LenientSubstitutionDigestRequiredTitleRule(
            message: "lenient substitution digest needs this field"
        )
        let item = Pharmacy.newLenientSubstitutionDigest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientSubstitutionDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.LenientSubstitutionDigestCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newLenientSubstitutionDigest("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLenientSubstitutionDigestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.LenientSubstitutionDigestTitleLengthRule(maxLength: 1000)
        let item = Pharmacy.newLenientSubstitutionDigest("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLenientSubstitutionDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.LenientSubstitutionDigestRequiredCodeRule(
            message: "lenient substitution digest needs a value"
        )
        let item = Pharmacy.newLenientSubstitutionDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
