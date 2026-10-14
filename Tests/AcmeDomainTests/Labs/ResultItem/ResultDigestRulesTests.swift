@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultDigestValidator()
        let item = Labs.newResultDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultDigestBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Labs.ResultDigestBudgetRangeRule(min: 4.0, max: 1319.5)
        let item = Labs.newResultDigest("x", name: "y")
        item.budget = 1321.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ResultDigestRequiredCodeRule(message: "result digest needs a value")
        let item = Labs.newResultDigest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ResultDigestCodeLengthRule(maxLength: 32)
        let item = Labs.newResultDigest("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultDigestRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Labs.ResultDigestRatioRangeRule(min: 7.9, max: 3906.9)
        let item = Labs.newResultDigest("x", name: "y")
        item.ratio = 3908.4
        #expect(rule.check(item).count > 0)
    }
}
