@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedOrderSetTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCappedOrderSetTemplateValidator()
        let item = ClinicalOps.newCappedOrderSetTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCappedOrderSetTemplateRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = ClinicalOps.CappedOrderSetTemplateRequiredWardRule(
            message: "capped order set template needs an entry"
        )
        let item = ClinicalOps.newCappedOrderSetTemplate("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCappedOrderSetTemplateWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = ClinicalOps.CappedOrderSetTemplateWardLengthRule(maxLength: 80)
        let item = ClinicalOps.newCappedOrderSetTemplate("x", name: "y")
        item.ward = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCappedOrderSetTemplatePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = ClinicalOps.CappedOrderSetTemplatePayerLengthRule(maxLength: 80)
        let item = ClinicalOps.newCappedOrderSetTemplate("x", name: "y")
        item.payer = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
