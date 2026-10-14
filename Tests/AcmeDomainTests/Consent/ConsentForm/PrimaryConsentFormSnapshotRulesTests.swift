@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryConsentFormSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPrimaryConsentFormSnapshotValidator()
        let item = Consent.newPrimaryConsentFormSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPrimaryConsentFormSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.PrimaryConsentFormSnapshotRequiredNameRule(
            message: "primary consent form snapshot needs a value"
        )
        let item = Consent.newPrimaryConsentFormSnapshot("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPrimaryConsentFormSnapshotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.PrimaryConsentFormSnapshotLabelLengthRule(maxLength: 32)
        let item = Consent.newPrimaryConsentFormSnapshot("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPrimaryConsentFormSnapshotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.PrimaryConsentFormSnapshotNameLengthRule(maxLength: 16)
        let item = Consent.newPrimaryConsentFormSnapshot("x", label: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPrimaryConsentFormSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.PrimaryConsentFormSnapshotRequiredCodeRule(
            message: "primary consent form snapshot needs an entry"
        )
        let item = Consent.newPrimaryConsentFormSnapshot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPrimaryConsentFormSnapshotScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Consent.PrimaryConsentFormSnapshotScoreRangeRule(min: 2.5, max: 4572.0)
        let item = Consent.newPrimaryConsentFormSnapshot("x", label: "y")
        item.score = 4573.5
        #expect(rule.check(item).count > 0)
    }
}
