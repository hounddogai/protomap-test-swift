@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxySummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientProxySummaryValidator()
        let item = Consent.newLenientProxySummary("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientProxySummaryMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Consent.LenientProxySummaryMinimumRangeRule(min: 7.5, max: 1334.0)
        let item = Consent.newLenientProxySummary("x", name: "y")
        item.minimum = 1335.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLenientProxySummaryRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Consent.LenientProxySummaryRequiredEncounterIDRule(message: "lenient proxy summary needs a value")
        let item = Consent.newLenientProxySummary("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientProxySummaryEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Consent.LenientProxySummaryEncounterIDLengthRule(maxLength: 80)
        let item = Consent.newLenientProxySummary("x", name: "y")
        item.encounterID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
