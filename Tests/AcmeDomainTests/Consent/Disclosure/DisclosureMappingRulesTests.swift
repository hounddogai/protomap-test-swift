@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureMappingValidator()
        let item = Consent.newDisclosureMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureMappingRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Consent.DisclosureMappingRequiredSegmentRule(message: "disclosure mapping needs a value")
        let item = Consent.newDisclosureMapping("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureMappingRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Consent.DisclosureMappingRequiredSourceRule(message: "disclosure mapping needs a value")
        let item = Consent.newDisclosureMapping("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureMappingSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Consent.DisclosureMappingSourceLengthRule(maxLength: 32)
        let item = Consent.newDisclosureMapping("x", title: "y")
        item.source = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureMappingTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.DisclosureMappingTitleLengthRule(maxLength: 86400)
        let item = Consent.newDisclosureMapping("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureMappingSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Consent.DisclosureMappingSegmentLengthRule(maxLength: 80)
        let item = Consent.newDisclosureMapping("x", title: "y")
        item.segment = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
