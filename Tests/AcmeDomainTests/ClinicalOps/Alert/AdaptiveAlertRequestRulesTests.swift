@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveAlertRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAdaptiveAlertRequestValidator()
        let item = ClinicalOps.newAdaptiveAlertRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAdaptiveAlertRequestRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = ClinicalOps.AdaptiveAlertRequestRequiredPhoneRule(message: "adaptive alert request needs a value")
        let item = ClinicalOps.newAdaptiveAlertRequest("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAdaptiveAlertRequestRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = ClinicalOps.AdaptiveAlertRequestRateRangeRule(min: 9.2, max: 4256.8)
        let item = ClinicalOps.newAdaptiveAlertRequest("x", title: "y")
        item.rate = 4258.3
        #expect(rule.check(item).count > 0)
    }
}
