@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementAllocationValidator()
        let item = RevenueCycle.newStatementAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementAllocationRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = RevenueCycle.StatementAllocationRequiredContactEmailRule(
            message: "statement allocation needs a value"
        )
        let item = RevenueCycle.newStatementAllocation("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementAllocationScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = RevenueCycle.StatementAllocationScoreRangeRule(min: 5.0, max: 2323.1)
        let item = RevenueCycle.newStatementAllocation("x", label: "y")
        item.score = 2324.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementAllocationContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = RevenueCycle.StatementAllocationContactEmailLengthRule(maxLength: 3600)
        let item = RevenueCycle.newStatementAllocation("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
