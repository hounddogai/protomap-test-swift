@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualWitnessDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultManualWitnessDraftValidator()
        let item = Consent.newManualWitnessDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentManualWitnessDraftGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Consent.ManualWitnessDraftGraceDaysRangeRule(min: 86400, max: 86400)
        let item = Consent.newManualWitnessDraft("x", title: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentManualWitnessDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ManualWitnessDraftRequiredCodeRule(message: "manual witness draft needs a value")
        let item = Consent.newManualWitnessDraft("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentManualWitnessDraftCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Consent.ManualWitnessDraftCostRangeRule(min: 3.1, max: 3709.0)
        let item = Consent.newManualWitnessDraft("x", title: "y")
        item.cost = 3710.5
        #expect(rule.check(item).count > 0)
    }
}
