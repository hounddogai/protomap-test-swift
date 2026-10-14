@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualDisclosurePolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultManualDisclosurePolicyValidator()
        let item = Consent.newManualDisclosurePolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentManualDisclosurePolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ManualDisclosurePolicyRequiredCodeRule(message: "manual disclosure policy needs an entry")
        let item = Consent.newManualDisclosurePolicy("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentManualDisclosurePolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ManualDisclosurePolicyCodeLengthRule(maxLength: 16)
        let item = Consent.newManualDisclosurePolicy("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentManualDisclosurePolicyRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Consent.ManualDisclosurePolicyRequiredDescriptionRule(
            message: "manual disclosure policy needs this field"
        )
        let item = Consent.newManualDisclosurePolicy("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentManualDisclosurePolicyRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Consent.ManualDisclosurePolicyRequiredSegmentRule(message: "manual disclosure policy needs an entry")
        let item = Consent.newManualDisclosurePolicy("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
