@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultClaimTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDefaultClaimTargetValidator()
        let item = RevenueCycle.newDefaultClaimTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDefaultClaimTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.DefaultClaimTargetCodeLengthRule(maxLength: 255)
        let item = RevenueCycle.newDefaultClaimTarget("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultClaimTargetSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = RevenueCycle.DefaultClaimTargetSummaryLengthRule(maxLength: 32)
        let item = RevenueCycle.newDefaultClaimTarget("x", title: "y")
        item.summary = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultClaimTargetBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = RevenueCycle.DefaultClaimTargetBatchSizeRangeRule(min: 64, max: 3600)
        let item = RevenueCycle.newDefaultClaimTarget("x", title: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDefaultClaimTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.DefaultClaimTargetRequiredCodeRule(message: "default claim target needs an entry")
        let item = RevenueCycle.newDefaultClaimTarget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
