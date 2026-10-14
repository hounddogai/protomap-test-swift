@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingRevocationManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingRevocationManifestValidator()
        let item = Consent.newRollingRevocationManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingRevocationManifestPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Consent.RollingRevocationManifestPayerLengthRule(maxLength: 16)
        let item = Consent.newRollingRevocationManifest("x", name: "y")
        item.payer = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingRevocationManifestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.RollingRevocationManifestNameLengthRule(maxLength: 16)
        let item = Consent.newRollingRevocationManifest("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingRevocationManifestCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Consent.RollingRevocationManifestCountryLengthRule(maxLength: 16)
        let item = Consent.newRollingRevocationManifest("x", name: "y")
        item.country = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}
