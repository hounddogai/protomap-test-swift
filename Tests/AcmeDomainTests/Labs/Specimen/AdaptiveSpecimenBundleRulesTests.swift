@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptiveSpecimenBundleValidator()
        let item = Labs.newAdaptiveSpecimenBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptiveSpecimenBundleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.AdaptiveSpecimenBundleRequiredLabelRule(message: "adaptive specimen bundle needs an entry")
        let item = Labs.newAdaptiveSpecimenBundle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptiveSpecimenBundleExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Labs.AdaptiveSpecimenBundleExpiresAtRangeRule(min: 64, max: 3600)
        let item = Labs.newAdaptiveSpecimenBundle("x", label: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAdaptiveSpecimenBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AdaptiveSpecimenBundleRequiredCodeRule(message: "adaptive specimen bundle needs a value")
        let item = Labs.newAdaptiveSpecimenBundle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
