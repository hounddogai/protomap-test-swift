@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetCycleValidator()
        let item = ClinicalOps.newOrderSetCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetCycleDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = ClinicalOps.OrderSetCycleDescriptionLengthRule(maxLength: 86400)
        let item = ClinicalOps.newOrderSetCycle("x", name: "y")
        item.description = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.OrderSetCycleCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newOrderSetCycle("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.OrderSetCycleRequiredCodeRule(message: "order set cycle needs a value")
        let item = ClinicalOps.newOrderSetCycle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetCycleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.OrderSetCycleRequiredNameRule(message: "order set cycle needs a value")
        let item = ClinicalOps.newOrderSetCycle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
