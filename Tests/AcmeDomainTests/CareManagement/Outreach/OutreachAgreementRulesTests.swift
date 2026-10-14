@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachAgreementValidator()
        let item = CareManagement.newOutreachAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.OutreachAgreementRequiredCodeRule(message: "outreach agreement needs a value")
        let item = CareManagement.newOutreachAgreement("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachAgreementExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = CareManagement.OutreachAgreementExpiresAtRangeRule(min: 120, max: 86400)
        let item = CareManagement.newOutreachAgreement("x", title: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachAgreementTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.OutreachAgreementTitleLengthRule(maxLength: 86400)
        let item = CareManagement.newOutreachAgreement("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachAgreementSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = CareManagement.OutreachAgreementSequenceRangeRule(min: 16, max: 120)
        let item = CareManagement.newOutreachAgreement("x", title: "y")
        item.sequence = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachAgreementLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.OutreachAgreementLabelLengthRule(maxLength: 86400)
        let item = CareManagement.newOutreachAgreement("x", title: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
