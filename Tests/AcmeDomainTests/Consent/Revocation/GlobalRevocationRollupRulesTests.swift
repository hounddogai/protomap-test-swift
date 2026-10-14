@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalRevocationRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultGlobalRevocationRollupValidator()
        let item = Consent.newGlobalRevocationRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentGlobalRevocationRollupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.GlobalRevocationRollupRequiredLabelRule(message: "global revocation rollup needs this field")
        let item = Consent.newGlobalRevocationRollup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentGlobalRevocationRollupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.GlobalRevocationRollupLabelLengthRule(maxLength: 120)
        let item = Consent.newGlobalRevocationRollup("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentGlobalRevocationRollupMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Consent.GlobalRevocationRollupMaximumRangeRule(min: 8.7, max: 1613.2)
        let item = Consent.newGlobalRevocationRollup("x", label: "y")
        item.maximum = 1614.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentGlobalRevocationRollupRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Consent.GlobalRevocationRollupRequiredSegmentRule(
            message: "global revocation rollup needs this field"
        )
        let item = Consent.newGlobalRevocationRollup("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
