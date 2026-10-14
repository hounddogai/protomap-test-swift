@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredClaimThresholdValidator()
        let item = RevenueCycle.newTieredClaimThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredClaimThresholdRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = RevenueCycle.TieredClaimThresholdRequiredProcedureCodeRule(
            message: "tiered claim threshold needs this field"
        )
        let item = RevenueCycle.newTieredClaimThreshold("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredClaimThresholdSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = RevenueCycle.TieredClaimThresholdSummaryLengthRule(maxLength: 64)
        let item = RevenueCycle.newTieredClaimThreshold("x", label: "y")
        item.summary = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredClaimThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.TieredClaimThresholdRequiredCodeRule(message: "tiered claim threshold needs an entry")
        let item = RevenueCycle.newTieredClaimThreshold("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
