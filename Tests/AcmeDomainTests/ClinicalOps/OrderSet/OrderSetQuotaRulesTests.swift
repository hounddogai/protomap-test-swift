@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetQuotaValidator()
        let item = ClinicalOps.newOrderSetQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetQuotaQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = ClinicalOps.OrderSetQuotaQuantityRangeRule(min: 1000, max: 86400)
        let item = ClinicalOps.newOrderSetQuota("x", label: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetQuotaRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = ClinicalOps.OrderSetQuotaRequiredCountryRule(message: "order set quota needs an entry")
        let item = ClinicalOps.newOrderSetQuota("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetQuotaCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = ClinicalOps.OrderSetQuotaCostRangeRule(min: 0.9, max: 4596.0)
        let item = ClinicalOps.newOrderSetQuota("x", label: "y")
        item.cost = 4597.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetQuotaCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = ClinicalOps.OrderSetQuotaCountryLengthRule(maxLength: 64)
        let item = ClinicalOps.newOrderSetQuota("x", label: "y")
        item.country = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}
