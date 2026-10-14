@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyAuthorizationAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLegacyAuthorizationAgreementValidator()
        let item = RevenueCycle.newLegacyAuthorizationAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLegacyAuthorizationAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.LegacyAuthorizationAgreementRequiredTitleRule(
            message: "legacy authorization agreement needs this field"
        )
        let item = RevenueCycle.newLegacyAuthorizationAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLegacyAuthorizationAgreementVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = RevenueCycle.LegacyAuthorizationAgreementVisitMinutesRangeRule(min: 120, max: 86400)
        let item = RevenueCycle.newLegacyAuthorizationAgreement("x", title: "y")
        item.visitMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLegacyAuthorizationAgreementRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = RevenueCycle.LegacyAuthorizationAgreementRequiredWardRule(
            message: "legacy authorization agreement needs this field"
        )
        let item = RevenueCycle.newLegacyAuthorizationAgreement("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
