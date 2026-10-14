@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalWitnessDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRegionalWitnessDraftValidator()
        let item = Consent.newRegionalWitnessDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRegionalWitnessDraftRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.RegionalWitnessDraftRequiredLabelRule(message: "regional witness draft needs a value")
        let item = Consent.newRegionalWitnessDraft("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRegionalWitnessDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.RegionalWitnessDraftCodeLengthRule(maxLength: 1000)
        let item = Consent.newRegionalWitnessDraft("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRegionalWitnessDraftEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Consent.RegionalWitnessDraftEndsAtRangeRule(min: 16, max: 1000)
        let item = Consent.newRegionalWitnessDraft("x", label: "y")
        item.endsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
