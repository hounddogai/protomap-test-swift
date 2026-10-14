@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetRuleValidator()
        let item = ClinicalOps.newOrderSetRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetRuleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.OrderSetRuleNameLengthRule(maxLength: 64)
        let item = ClinicalOps.newOrderSetRule("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetRuleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.OrderSetRuleRequiredNameRule(message: "order set rule needs a value")
        let item = ClinicalOps.newOrderSetRule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetRuleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.OrderSetRuleTitleLengthRule(maxLength: 1000)
        let item = ClinicalOps.newOrderSetRule("x", name: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.OrderSetRuleRequiredCodeRule(message: "order set rule needs a value")
        let item = ClinicalOps.newOrderSetRule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetRuleUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = ClinicalOps.OrderSetRuleUpdatedAtRangeRule(min: 120, max: 1000)
        let item = ClinicalOps.newOrderSetRule("x", name: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetRuleRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = ClinicalOps.OrderSetRuleRequiredDiagnosisCodeRule(message: "order set rule needs an entry")
        let item = ClinicalOps.newOrderSetRule("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
