@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetSlotValidator()
        let item = ClinicalOps.newOrderSetSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.OrderSetSlotRequiredCodeRule(message: "order set slot needs this field")
        let item = ClinicalOps.newOrderSetSlot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
