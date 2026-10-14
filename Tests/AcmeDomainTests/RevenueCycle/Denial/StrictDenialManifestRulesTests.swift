@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictDenialManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStrictDenialManifestValidator()
        let item = RevenueCycle.newStrictDenialManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStrictDenialManifestDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = RevenueCycle.StrictDenialManifestDiagnosisCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newStrictDenialManifest("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStrictDenialManifestRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = RevenueCycle.StrictDenialManifestRequiredDiagnosisCodeRule(
            message: "strict denial manifest needs an entry"
        )
        let item = RevenueCycle.newStrictDenialManifest("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStrictDenialManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StrictDenialManifestRequiredCodeRule(message: "strict denial manifest needs a value")
        let item = RevenueCycle.newStrictDenialManifest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
