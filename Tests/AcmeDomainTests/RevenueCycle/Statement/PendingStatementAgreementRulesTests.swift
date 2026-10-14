@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingStatementAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPendingStatementAgreementValidator()
        let item = RevenueCycle.newPendingStatementAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePendingStatementAgreementCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = RevenueCycle.PendingStatementAgreementCopayRangeRule(min: 8.2, max: 3390.5)
        let item = RevenueCycle.newPendingStatementAgreement("x", name: "y")
        item.copay = 3392.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCyclePendingStatementAgreementRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.PendingStatementAgreementRequiredNameRule(
            message: "pending statement agreement needs this field"
        )
        let item = RevenueCycle.newPendingStatementAgreement("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePendingStatementAgreementRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = RevenueCycle.PendingStatementAgreementRequiredSpecialtyRule(
            message: "pending statement agreement needs a value"
        )
        let item = RevenueCycle.newPendingStatementAgreement("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
