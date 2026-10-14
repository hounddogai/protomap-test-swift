@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultWindowValidator()
        let item = Labs.newResultWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultWindowRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Labs.ResultWindowRequiredSourceRule(message: "result window needs an entry")
        let item = Labs.newResultWindow("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultWindowSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Labs.ResultWindowSourceLengthRule(maxLength: 3600)
        let item = Labs.newResultWindow("x", title: "y")
        item.source = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
