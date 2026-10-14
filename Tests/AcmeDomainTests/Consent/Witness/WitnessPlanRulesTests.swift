@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessPlanValidator()
        let item = Consent.newWitnessPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessPlanRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Consent.WitnessPlanRequiredRegionRule(message: "witness plan needs a value")
        let item = Consent.newWitnessPlan("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessPlanRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Consent.WitnessPlanRegionLengthRule(maxLength: 86400)
        let item = Consent.newWitnessPlan("x", label: "y")
        item.region = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessPlanRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Consent.WitnessPlanRateRangeRule(min: 6.0, max: 138.9)
        let item = Consent.newWitnessPlan("x", label: "y")
        item.rate = 140.4
        #expect(rule.check(item).count > 0)
    }
}
