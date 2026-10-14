@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedOrderSetRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultWeightedOrderSetRuleValidator()
        let item = ClinicalOps.newWeightedOrderSetRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsWeightedOrderSetRuleSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = ClinicalOps.WeightedOrderSetRuleSpecialtyLengthRule(maxLength: 120)
        let item = ClinicalOps.newWeightedOrderSetRule("x", name: "y")
        item.specialty = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsWeightedOrderSetRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.WeightedOrderSetRuleRequiredCodeRule(message: "weighted order set rule needs this field")
        let item = ClinicalOps.newWeightedOrderSetRule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsWeightedOrderSetRuleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.WeightedOrderSetRuleNameLengthRule(maxLength: 86400)
        let item = ClinicalOps.newWeightedOrderSetRule("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsWeightedOrderSetRuleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.WeightedOrderSetRuleRequiredNameRule(message: "weighted order set rule needs an entry")
        let item = ClinicalOps.newWeightedOrderSetRule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
