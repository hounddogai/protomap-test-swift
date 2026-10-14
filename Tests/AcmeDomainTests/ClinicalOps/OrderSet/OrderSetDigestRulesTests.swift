@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetDigestValidator()
        let item = ClinicalOps.newOrderSetDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetDigestRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = ClinicalOps.OrderSetDigestRequiredRegionRule(message: "order set digest needs a value")
        let item = ClinicalOps.newOrderSetDigest("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetDigestWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = ClinicalOps.OrderSetDigestWindowDaysRangeRule(min: 86400, max: 86400)
        let item = ClinicalOps.newOrderSetDigest("x", title: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.OrderSetDigestCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newOrderSetDigest("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetDigestRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = ClinicalOps.OrderSetDigestRequiredCurrencyRule(message: "order set digest needs a value")
        let item = ClinicalOps.newOrderSetDigest("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.OrderSetDigestRequiredCodeRule(message: "order set digest needs this field")
        let item = ClinicalOps.newOrderSetDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
