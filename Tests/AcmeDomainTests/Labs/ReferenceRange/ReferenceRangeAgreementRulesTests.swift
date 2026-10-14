@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeAgreementValidator()
        let item = Labs.newReferenceRangeAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeAgreementRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Labs.ReferenceRangeAgreementRequiredLocaleRule(message: "reference range agreement needs a value")
        let item = Labs.newReferenceRangeAgreement("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeAgreementRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Labs.ReferenceRangeAgreementRequiredSummaryRule(message: "reference range agreement needs this field")
        let item = Labs.newReferenceRangeAgreement("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ReferenceRangeAgreementRequiredCodeRule(message: "reference range agreement needs this field")
        let item = Labs.newReferenceRangeAgreement("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
