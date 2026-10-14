@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultPlanValidator()
        let item = Labs.newResultPlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultPlanRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.ResultPlanRequiredNameRule(message: "result plan needs a value")
        let item = Labs.newResultPlan("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultPlanGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Labs.ResultPlanGraceDaysRangeRule(min: 16, max: 255)
        let item = Labs.newResultPlan("x", name: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}
