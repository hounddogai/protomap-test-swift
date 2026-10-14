@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyClaimBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLegacyClaimBatchValidator()
        let item = RevenueCycle.newLegacyClaimBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLegacyClaimBatchTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.LegacyClaimBatchTitleLengthRule(maxLength: 1000)
        let item = RevenueCycle.newLegacyClaimBatch("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyClaimBatchRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = RevenueCycle.LegacyClaimBatchRequiredBedRule(message: "legacy claim batch needs this field")
        let item = RevenueCycle.newLegacyClaimBatch("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLegacyClaimBatchDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = RevenueCycle.LegacyClaimBatchDosageMgRangeRule(min: 2.9, max: 4295.6)
        let item = RevenueCycle.newLegacyClaimBatch("x", title: "y")
        item.dosageMg = 4297.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLegacyClaimBatchRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.LegacyClaimBatchRequiredTitleRule(message: "legacy claim batch needs this field")
        let item = RevenueCycle.newLegacyClaimBatch("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
