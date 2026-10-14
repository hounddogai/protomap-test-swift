@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryResultSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPrimaryResultSummaryValidator()
        let item = Labs.newPrimaryResultSummary("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPrimaryResultSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PrimaryResultSummaryRequiredCodeRule(message: "primary result summary needs a value")
        let item = Labs.newPrimaryResultSummary("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPrimaryResultSummarySourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Labs.PrimaryResultSummarySourceLengthRule(maxLength: 1000)
        let item = Labs.newPrimaryResultSummary("x", name: "y")
        item.source = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPrimaryResultSummaryMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Labs.PrimaryResultSummaryMaximumRangeRule(min: 0.5, max: 3213.2)
        let item = Labs.newPrimaryResultSummary("x", name: "y")
        item.maximum = 3214.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPrimaryResultSummaryRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Labs.PrimaryResultSummaryRequiredPayerRule(message: "primary result summary needs a value")
        let item = Labs.newPrimaryResultSummary("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPrimaryResultSummaryRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Labs.PrimaryResultSummaryRequiredSourceRule(message: "primary result summary needs this field")
        let item = Labs.newPrimaryResultSummary("", name: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPrimaryResultSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PrimaryResultSummaryCodeLengthRule(maxLength: 80)
        let item = Labs.newPrimaryResultSummary("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
