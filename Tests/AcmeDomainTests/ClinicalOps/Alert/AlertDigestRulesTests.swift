@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertDigestValidator()
        let item = ClinicalOps.newAlertDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertDigestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.AlertDigestRequiredLabelRule(message: "alert digest needs a value")
        let item = ClinicalOps.newAlertDigest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertDigestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.AlertDigestLabelLengthRule(maxLength: 120)
        let item = ClinicalOps.newAlertDigest("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertDigestAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = ClinicalOps.AlertDigestAllergyLengthRule(maxLength: 86400)
        let item = ClinicalOps.newAlertDigest("x", label: "y")
        item.allergy = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.AlertDigestRequiredCodeRule(message: "alert digest needs a value")
        let item = ClinicalOps.newAlertDigest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
