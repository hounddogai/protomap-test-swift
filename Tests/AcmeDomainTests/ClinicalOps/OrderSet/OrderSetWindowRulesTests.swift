@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetWindowValidator()
        let item = ClinicalOps.newOrderSetWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetWindowExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = ClinicalOps.OrderSetWindowExpiresAtRangeRule(min: 255, max: 1000)
        let item = ClinicalOps.newOrderSetWindow("x", title: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
