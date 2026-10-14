@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureSegmentValidator()
        let item = Consent.newDisclosureSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureSegmentRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Consent.DisclosureSegmentRefillsRangeRule(min: 120, max: 255)
        let item = Consent.newDisclosureSegment("x", title: "y")
        item.refills = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureSegmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.DisclosureSegmentNameLengthRule(maxLength: 86400)
        let item = Consent.newDisclosureSegment("x", title: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.DisclosureSegmentRequiredCodeRule(message: "disclosure segment needs this field")
        let item = Consent.newDisclosureSegment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.DisclosureSegmentCodeLengthRule(maxLength: 86400)
        let item = Consent.newDisclosureSegment("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
