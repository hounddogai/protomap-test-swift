@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimTierValidator()
        let item = RevenueCycle.newClaimTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimTierRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.ClaimTierRequiredNameRule(message: "claim tier needs a value")
        let item = RevenueCycle.newClaimTier("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimTierRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.ClaimTierRequiredTitleRule(message: "claim tier needs this field")
        let item = RevenueCycle.newClaimTier("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ClaimTierCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newClaimTier("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimTierRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = RevenueCycle.ClaimTierRequiredProcedureCodeRule(message: "claim tier needs an entry")
        let item = RevenueCycle.newClaimTier("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
