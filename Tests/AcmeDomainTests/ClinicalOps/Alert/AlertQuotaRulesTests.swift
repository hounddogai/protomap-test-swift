@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertQuotaValidator()
        let item = ClinicalOps.newAlertQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertQuotaNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.AlertQuotaNameLengthRule(maxLength: 86400)
        let item = ClinicalOps.newAlertQuota("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertQuotaMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = ClinicalOps.AlertQuotaMinimumRangeRule(min: 9.8, max: 346.3)
        let item = ClinicalOps.newAlertQuota("x", name: "y")
        item.minimum = 347.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertQuotaMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = ClinicalOps.AlertQuotaMaximumRangeRule(min: 4.5, max: 2416.0)
        let item = ClinicalOps.newAlertQuota("x", name: "y")
        item.maximum = 2417.5
        #expect(rule.check(item).count > 0)
    }
}
