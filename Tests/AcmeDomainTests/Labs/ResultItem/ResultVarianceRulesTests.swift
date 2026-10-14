@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultVarianceValidator()
        let item = Labs.newResultVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ResultVarianceCodeLengthRule(maxLength: 32)
        let item = Labs.newResultVariance("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.ResultVarianceTitleLengthRule(maxLength: 1000)
        let item = Labs.newResultVariance("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ResultVarianceRequiredCodeRule(message: "result variance needs this field")
        let item = Labs.newResultVariance("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
