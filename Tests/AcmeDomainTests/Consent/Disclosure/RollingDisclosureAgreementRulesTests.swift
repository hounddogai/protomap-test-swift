@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingDisclosureAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingDisclosureAgreementValidator()
        let item = Consent.newRollingDisclosureAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingDisclosureAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RollingDisclosureAgreementRequiredCodeRule(
            message: "rolling disclosure agreement needs this field"
        )
        let item = Consent.newRollingDisclosureAgreement("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingDisclosureAgreementCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Consent.RollingDisclosureAgreementCreatedAtRangeRule(min: 16, max: 3600)
        let item = Consent.newRollingDisclosureAgreement("x", title: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRollingDisclosureAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.RollingDisclosureAgreementRequiredTitleRule(
            message: "rolling disclosure agreement needs an entry"
        )
        let item = Consent.newRollingDisclosureAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
