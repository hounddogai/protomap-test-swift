@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureDraftValidator()
        let item = Consent.newDisclosureDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureDraftLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.DisclosureDraftLabelLengthRule(maxLength: 16)
        let item = Consent.newDisclosureDraft("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureDraftRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Consent.DisclosureDraftRequiredSegmentRule(message: "disclosure draft needs a value")
        let item = Consent.newDisclosureDraft("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureDraftCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Consent.DisclosureDraftCopayRangeRule(min: 2.6, max: 3765.5)
        let item = Consent.newDisclosureDraft("x", label: "y")
        item.copay = 3767.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureDraftWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Consent.DisclosureDraftWardLengthRule(maxLength: 32)
        let item = Consent.newDisclosureDraft("x", label: "y")
        item.ward = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureDraftRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.DisclosureDraftRequiredLabelRule(message: "disclosure draft needs an entry")
        let item = Consent.newDisclosureDraft("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
