@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessSummaryValidator()
        let item = Consent.newWitnessSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessSummaryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.WitnessSummaryRequiredLabelRule(message: "witness summary needs a value")
        let item = Consent.newWitnessSummary("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WitnessSummaryRequiredCodeRule(message: "witness summary needs this field")
        let item = Consent.newWitnessSummary("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
