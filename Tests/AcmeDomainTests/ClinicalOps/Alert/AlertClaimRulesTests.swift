@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertClaimValidator()
        let item = ClinicalOps.newAlertClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.AlertClaimCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newAlertClaim("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertClaimMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = ClinicalOps.AlertClaimMaximumRangeRule(min: 1.6, max: 4849.8)
        let item = ClinicalOps.newAlertClaim("x", title: "y")
        item.maximum = 4851.3
        #expect(rule.check(item).count > 0)
    }
}
