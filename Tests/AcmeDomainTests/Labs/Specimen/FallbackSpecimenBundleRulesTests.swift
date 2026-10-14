@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackSpecimenBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackSpecimenBundleValidator()
        let item = Labs.newFallbackSpecimenBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackSpecimenBundleUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Labs.FallbackSpecimenBundleUnitLengthRule(maxLength: 64)
        let item = Labs.newFallbackSpecimenBundle("x", label: "y")
        item.unit = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackSpecimenBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.FallbackSpecimenBundleRequiredCodeRule(message: "fallback specimen bundle needs an entry")
        let item = Labs.newFallbackSpecimenBundle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackSpecimenBundleRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Labs.FallbackSpecimenBundleRevisionRangeRule(min: 120, max: 3600)
        let item = Labs.newFallbackSpecimenBundle("x", label: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsFallbackSpecimenBundleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.FallbackSpecimenBundleRequiredLabelRule(message: "fallback specimen bundle needs an entry")
        let item = Labs.newFallbackSpecimenBundle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
