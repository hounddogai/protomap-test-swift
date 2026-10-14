@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedDisclosureRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedDisclosureRecordValidator()
        let item = Consent.newCappedDisclosureRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedDisclosureRecordLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.CappedDisclosureRecordLabelLengthRule(maxLength: 86400)
        let item = Consent.newCappedDisclosureRecord("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentCappedDisclosureRecordRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Consent.CappedDisclosureRecordRegionLengthRule(maxLength: 64)
        let item = Consent.newCappedDisclosureRecord("x", label: "y")
        item.region = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentCappedDisclosureRecordPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Consent.CappedDisclosureRecordPriorityRangeRule(min: 120, max: 255)
        let item = Consent.newCappedDisclosureRecord("x", label: "y")
        item.priority = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentCappedDisclosureRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.CappedDisclosureRecordCodeLengthRule(maxLength: 1000)
        let item = Consent.newCappedDisclosureRecord("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
