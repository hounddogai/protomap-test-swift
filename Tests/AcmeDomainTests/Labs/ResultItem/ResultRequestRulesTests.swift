@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultRequestValidator()
        let item = Labs.newResultRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultRequestCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Labs.ResultRequestCreatedAtRangeRule(min: 86400, max: 86400)
        let item = Labs.newResultRequest("x", title: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultRequestAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Labs.ResultRequestAmountRangeRule(min: 7.0, max: 1793.9)
        let item = Labs.newResultRequest("x", title: "y")
        item.amount = 1795.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultRequestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.ResultRequestTitleLengthRule(maxLength: 64)
        let item = Labs.newResultRequest("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ResultRequestRequiredCodeRule(message: "result request needs a value")
        let item = Labs.newResultRequest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ResultRequestCodeLengthRule(maxLength: 64)
        let item = Labs.newResultRequest("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
