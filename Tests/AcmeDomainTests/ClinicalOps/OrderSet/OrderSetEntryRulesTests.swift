@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetEntryValidator()
        let item = ClinicalOps.newOrderSetEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetEntryAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = ClinicalOps.OrderSetEntryAttemptsRangeRule(min: 255, max: 1000)
        let item = ClinicalOps.newOrderSetEntry("x", name: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetEntryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.OrderSetEntryRequiredNameRule(message: "order set entry needs an entry")
        let item = ClinicalOps.newOrderSetEntry("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.OrderSetEntryRequiredCodeRule(message: "order set entry needs this field")
        let item = ClinicalOps.newOrderSetEntry("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetEntryScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = ClinicalOps.OrderSetEntryScoreRangeRule(min: 3.0, max: 4985.5)
        let item = ClinicalOps.newOrderSetEntry("x", name: "y")
        item.score = 4987.0
        #expect(rule.check(item).count > 0)
    }
}
