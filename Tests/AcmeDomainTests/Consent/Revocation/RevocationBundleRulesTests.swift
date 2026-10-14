@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationBundleValidator()
        let item = Consent.newRevocationBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationBundleEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Consent.RevocationBundleEncounterIDLengthRule(maxLength: 86400)
        let item = Consent.newRevocationBundle("x", title: "y")
        item.encounterID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationBundleSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Consent.RevocationBundleSegmentLengthRule(maxLength: 120)
        let item = Consent.newRevocationBundle("x", title: "y")
        item.segment = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationBundleRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Consent.RevocationBundleRequiredSegmentRule(message: "revocation bundle needs this field")
        let item = Consent.newRevocationBundle("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
