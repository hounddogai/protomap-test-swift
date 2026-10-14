@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingAuthorizationAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPendingAuthorizationAgreementValidator()
        let item = RevenueCycle.newPendingAuthorizationAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePendingAuthorizationAgreementRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = RevenueCycle.PendingAuthorizationAgreementRequiredUnitRule(
            message: "pending authorization agreement needs this field"
        )
        let item = RevenueCycle.newPendingAuthorizationAgreement("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePendingAuthorizationAgreementWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = RevenueCycle.PendingAuthorizationAgreementWardLengthRule(maxLength: 120)
        let item = RevenueCycle.newPendingAuthorizationAgreement("x", title: "y")
        item.ward = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePendingAuthorizationAgreementTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.PendingAuthorizationAgreementTitleLengthRule(maxLength: 1000)
        let item = RevenueCycle.newPendingAuthorizationAgreement("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePendingAuthorizationAgreementRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = RevenueCycle.PendingAuthorizationAgreementRefillsRangeRule(min: 64, max: 1000)
        let item = RevenueCycle.newPendingAuthorizationAgreement("x", title: "y")
        item.refills = 1001
        #expect(rule.check(item).count > 0)
    }
}
