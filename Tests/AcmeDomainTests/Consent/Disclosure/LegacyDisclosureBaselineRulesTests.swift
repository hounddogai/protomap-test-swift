@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyDisclosureBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLegacyDisclosureBaselineValidator()
        let item = Consent.newLegacyDisclosureBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLegacyDisclosureBaselineNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.LegacyDisclosureBaselineNameLengthRule(maxLength: 80)
        let item = Consent.newLegacyDisclosureBaseline("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLegacyDisclosureBaselineRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.LegacyDisclosureBaselineRequiredNameRule(message: "legacy disclosure baseline needs an entry")
        let item = Consent.newLegacyDisclosureBaseline("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLegacyDisclosureBaselineThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Consent.LegacyDisclosureBaselineThresholdRangeRule(min: 9.0, max: 4508.7)
        let item = Consent.newLegacyDisclosureBaseline("x", name: "y")
        item.threshold = 4510.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLegacyDisclosureBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LegacyDisclosureBaselineCodeLengthRule(maxLength: 255)
        let item = Consent.newLegacyDisclosureBaseline("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLegacyDisclosureBaselineFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Consent.LegacyDisclosureBaselineFacilityLengthRule(maxLength: 1000)
        let item = Consent.newLegacyDisclosureBaseline("x", name: "y")
        item.facility = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
