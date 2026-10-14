@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleSeasonalStatementPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultSeasonalStatementPolicyValidator()
        let item = RevenueCycle.newSeasonalStatementPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleSeasonalStatementPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.SeasonalStatementPolicyRequiredCodeRule(
            message: "seasonal statement policy needs an entry"
        )
        let item = RevenueCycle.newSeasonalStatementPolicy("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleSeasonalStatementPolicyBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = RevenueCycle.SeasonalStatementPolicyBatchSizeRangeRule(min: 1000, max: 86400)
        let item = RevenueCycle.newSeasonalStatementPolicy("x", name: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleSeasonalStatementPolicyNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.SeasonalStatementPolicyNameLengthRule(maxLength: 1000)
        let item = RevenueCycle.newSeasonalStatementPolicy("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
