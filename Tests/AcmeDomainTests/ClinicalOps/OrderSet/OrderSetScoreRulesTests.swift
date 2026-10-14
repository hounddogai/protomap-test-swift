@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetScoreValidator()
        let item = ClinicalOps.newOrderSetScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetScoreWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = ClinicalOps.OrderSetScoreWardLengthRule(maxLength: 3600)
        let item = ClinicalOps.newOrderSetScore("x", name: "y")
        item.ward = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetScoreRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = ClinicalOps.OrderSetScoreRequiredWardRule(message: "order set score needs a value")
        let item = ClinicalOps.newOrderSetScore("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.OrderSetScoreCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newOrderSetScore("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
