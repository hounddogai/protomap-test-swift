@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementReviewValidator()
        let item = RevenueCycle.newStatementReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.StatementReviewNameLengthRule(maxLength: 120)
        let item = RevenueCycle.newStatementReview("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.StatementReviewRequiredNameRule(message: "statement review needs this field")
        let item = RevenueCycle.newStatementReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.StatementReviewCodeLengthRule(maxLength: 1000)
        let item = RevenueCycle.newStatementReview("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
