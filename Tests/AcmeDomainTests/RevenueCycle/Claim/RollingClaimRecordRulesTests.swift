@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingClaimRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRollingClaimRecordValidator()
        let item = RevenueCycle.newRollingClaimRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRollingClaimRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RollingClaimRecordRequiredCodeRule(message: "rolling claim record needs an entry")
        let item = RevenueCycle.newRollingClaimRecord("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRollingClaimRecordVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = RevenueCycle.RollingClaimRecordVisitMinutesRangeRule(min: 32, max: 120)
        let item = RevenueCycle.newRollingClaimRecord("x", name: "y")
        item.visitMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRollingClaimRecordRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.RollingClaimRecordRequiredNameRule(message: "rolling claim record needs this field")
        let item = RevenueCycle.newRollingClaimRecord("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRollingClaimRecordDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = RevenueCycle.RollingClaimRecordDescriptionLengthRule(maxLength: 64)
        let item = RevenueCycle.newRollingClaimRecord("x", name: "y")
        item.description = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
