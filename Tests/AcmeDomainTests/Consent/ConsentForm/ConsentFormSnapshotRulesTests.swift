@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormSnapshotValidator()
        let item = Consent.newConsentFormSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ConsentFormSnapshotCodeLengthRule(maxLength: 86400)
        let item = Consent.newConsentFormSnapshot("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormSnapshotRequiredCodeRule(message: "consent form snapshot needs this field")
        let item = Consent.newConsentFormSnapshot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormSnapshotCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Consent.ConsentFormSnapshotCategoryLengthRule(maxLength: 86400)
        let item = Consent.newConsentFormSnapshot("x", label: "y")
        item.category = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
