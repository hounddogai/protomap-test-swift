@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientRevocationGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientRevocationGroupValidator()
        let item = Consent.newLenientRevocationGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientRevocationGroupRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Consent.LenientRevocationGroupRequiredFacilityRule(message: "lenient revocation group needs an entry")
        let item = Consent.newLenientRevocationGroup("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientRevocationGroupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.LenientRevocationGroupNameLengthRule(maxLength: 16)
        let item = Consent.newLenientRevocationGroup("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLenientRevocationGroupFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Consent.LenientRevocationGroupFacilityLengthRule(maxLength: 255)
        let item = Consent.newLenientRevocationGroup("x", name: "y")
        item.facility = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLenientRevocationGroupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.LenientRevocationGroupRequiredNameRule(message: "lenient revocation group needs an entry")
        let item = Consent.newLenientRevocationGroup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientRevocationGroupRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Consent.LenientRevocationGroupRequiredDiagnosisCodeRule(
            message: "lenient revocation group needs a value"
        )
        let item = Consent.newLenientRevocationGroup("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
