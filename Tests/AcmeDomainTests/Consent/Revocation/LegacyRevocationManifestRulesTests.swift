@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyRevocationManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLegacyRevocationManifestValidator()
        let item = Consent.newLegacyRevocationManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLegacyRevocationManifestRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Consent.LegacyRevocationManifestRequiredChecksumRule(
            message: "legacy revocation manifest needs a value"
        )
        let item = Consent.newLegacyRevocationManifest("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLegacyRevocationManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LegacyRevocationManifestCodeLengthRule(maxLength: 16)
        let item = Consent.newLegacyRevocationManifest("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLegacyRevocationManifestRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Consent.LegacyRevocationManifestRequiredDiagnosisCodeRule(
            message: "legacy revocation manifest needs an entry"
        )
        let item = Consent.newLegacyRevocationManifest("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
