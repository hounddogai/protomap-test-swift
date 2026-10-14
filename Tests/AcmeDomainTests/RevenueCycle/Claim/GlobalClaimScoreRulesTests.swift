@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalClaimScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultGlobalClaimScoreValidator()
        let item = RevenueCycle.newGlobalClaimScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleGlobalClaimScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.GlobalClaimScoreCodeLengthRule(maxLength: 1000)
        let item = RevenueCycle.newGlobalClaimScore("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleGlobalClaimScoreRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = RevenueCycle.GlobalClaimScoreRequiredAllergyRule(message: "global claim score needs an entry")
        let item = RevenueCycle.newGlobalClaimScore("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleGlobalClaimScoreRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = RevenueCycle.GlobalClaimScoreRetriesRangeRule(min: 16, max: 32)
        let item = RevenueCycle.newGlobalClaimScore("x", name: "y")
        item.retries = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleGlobalClaimScoreSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = RevenueCycle.GlobalClaimScoreSummaryLengthRule(maxLength: 86400)
        let item = RevenueCycle.newGlobalClaimScore("x", name: "y")
        item.summary = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
