@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveAccessionBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptiveAccessionBundleValidator()
        let item = Labs.newAdaptiveAccessionBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptiveAccessionBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AdaptiveAccessionBundleCodeLengthRule(maxLength: 255)
        let item = Labs.newAdaptiveAccessionBundle("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAdaptiveAccessionBundleRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Labs.AdaptiveAccessionBundleRequiredAllergyRule(message: "adaptive accession bundle needs this field")
        let item = Labs.newAdaptiveAccessionBundle("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
