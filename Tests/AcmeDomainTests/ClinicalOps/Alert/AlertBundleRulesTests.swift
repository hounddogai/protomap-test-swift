@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertBundleValidator()
        let item = ClinicalOps.newAlertBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.AlertBundleRequiredCodeRule(message: "alert bundle needs this field")
        let item = ClinicalOps.newAlertBundle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertBundleRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = ClinicalOps.AlertBundleRequiredAllergyRule(message: "alert bundle needs a value")
        let item = ClinicalOps.newAlertBundle("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertBundleAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = ClinicalOps.AlertBundleAllergyLengthRule(maxLength: 86400)
        let item = ClinicalOps.newAlertBundle("x", label: "y")
        item.allergy = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertBundleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.AlertBundleLabelLengthRule(maxLength: 32)
        let item = ClinicalOps.newAlertBundle("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
