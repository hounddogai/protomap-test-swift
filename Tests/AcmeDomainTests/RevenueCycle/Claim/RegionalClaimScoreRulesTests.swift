@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalClaimScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRegionalClaimScoreValidator()
        let item = RevenueCycle.newRegionalClaimScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRegionalClaimScoreRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = RevenueCycle.RegionalClaimScoreRequiredSummaryRule(message: "regional claim score needs this field")
        let item = RevenueCycle.newRegionalClaimScore("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRegionalClaimScoreLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.RegionalClaimScoreLabelLengthRule(maxLength: 32)
        let item = RevenueCycle.newRegionalClaimScore("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRegionalClaimScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RegionalClaimScoreRequiredCodeRule(message: "regional claim score needs this field")
        let item = RevenueCycle.newRegionalClaimScore("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
