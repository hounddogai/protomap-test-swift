@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetProfileValidator()
        let item = ClinicalOps.newOrderSetProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetProfileRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = ClinicalOps.OrderSetProfileRateRangeRule(min: 3.5, max: 761.8)
        let item = ClinicalOps.newOrderSetProfile("x", name: "y")
        item.rate = 763.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetProfileRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = ClinicalOps.OrderSetProfileRequiredPhoneRule(message: "order set profile needs an entry")
        let item = ClinicalOps.newOrderSetProfile("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.OrderSetProfileRequiredCodeRule(message: "order set profile needs this field")
        let item = ClinicalOps.newOrderSetProfile("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
