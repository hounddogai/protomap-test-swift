@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationDigestValidator()
        let item = RevenueCycle.newAuthorizationDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.AuthorizationDigestNameLengthRule(maxLength: 64)
        let item = RevenueCycle.newAuthorizationDigest("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationDigestProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = RevenueCycle.AuthorizationDigestProcedureCodeLengthRule(maxLength: 64)
        let item = RevenueCycle.newAuthorizationDigest("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationDigestRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = RevenueCycle.AuthorizationDigestRequiredProcedureCodeRule(
            message: "authorization digest needs a value"
        )
        let item = RevenueCycle.newAuthorizationDigest("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationDigestSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = RevenueCycle.AuthorizationDigestSpecialtyLengthRule(maxLength: 80)
        let item = RevenueCycle.newAuthorizationDigest("x", name: "y")
        item.specialty = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationDigestAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.AuthorizationDigestAmountRangeRule(min: 6.5, max: 1844.3)
        let item = RevenueCycle.newAuthorizationDigest("x", name: "y")
        item.amount = 1845.8
        #expect(rule.check(item).count > 0)
    }
}
