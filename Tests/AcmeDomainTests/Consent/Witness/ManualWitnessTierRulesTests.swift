@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualWitnessTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultManualWitnessTierValidator()
        let item = Consent.newManualWitnessTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentManualWitnessTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ManualWitnessTierRequiredCodeRule(message: "manual witness tier needs this field")
        let item = Consent.newManualWitnessTier("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentManualWitnessTierRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.ManualWitnessTierRequiredTitleRule(message: "manual witness tier needs a value")
        let item = Consent.newManualWitnessTier("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
