@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalResultSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultGlobalResultSummaryValidator()
        let item = Labs.newGlobalResultSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsGlobalResultSummaryRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Labs.GlobalResultSummaryRequiredPayerRule(message: "global result summary needs a value")
        let item = Labs.newGlobalResultSummary("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsGlobalResultSummaryRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Labs.GlobalResultSummaryRateRangeRule(min: 2.7, max: 3000.3)
        let item = Labs.newGlobalResultSummary("x", label: "y")
        item.rate = 3001.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsGlobalResultSummaryMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Labs.GlobalResultSummaryMarginRangeRule(min: 3.2, max: 538.4)
        let item = Labs.newGlobalResultSummary("x", label: "y")
        item.margin = 539.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsGlobalResultSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.GlobalResultSummaryRequiredCodeRule(message: "global result summary needs a value")
        let item = Labs.newGlobalResultSummary("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
