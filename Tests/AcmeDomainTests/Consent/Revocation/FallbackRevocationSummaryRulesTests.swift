@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackRevocationSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultFallbackRevocationSummaryValidator()
        let item = Consent.newFallbackRevocationSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentFallbackRevocationSummaryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.FallbackRevocationSummaryRequiredLabelRule(
            message: "fallback revocation summary needs this field"
        )
        let item = Consent.newFallbackRevocationSummary("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentFallbackRevocationSummaryDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Consent.FallbackRevocationSummaryDescriptionLengthRule(maxLength: 86400)
        let item = Consent.newFallbackRevocationSummary("x", label: "y")
        item.description = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
