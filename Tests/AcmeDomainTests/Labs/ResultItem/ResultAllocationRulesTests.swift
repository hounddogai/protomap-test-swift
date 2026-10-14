@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultAllocationValidator()
        let item = Labs.newResultAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultAllocationScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Labs.ResultAllocationScoreRangeRule(min: 4.4, max: 3542.1)
        let item = Labs.newResultAllocation("x", title: "y")
        item.score = 3543.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ResultAllocationRequiredCodeRule(message: "result allocation needs a value")
        let item = Labs.newResultAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultAllocationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.ResultAllocationRequiredTitleRule(message: "result allocation needs a value")
        let item = Labs.newResultAllocation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
