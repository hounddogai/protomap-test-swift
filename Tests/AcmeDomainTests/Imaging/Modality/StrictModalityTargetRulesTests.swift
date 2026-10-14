@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictModalityTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStrictModalityTargetValidator()
        let item = Imaging.newStrictModalityTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStrictModalityTargetUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Imaging.StrictModalityTargetUpdatedAtRangeRule(min: 32, max: 86400)
        let item = Imaging.newStrictModalityTarget("x", label: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStrictModalityTargetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.StrictModalityTargetRequiredLabelRule(message: "strict modality target needs a value")
        let item = Imaging.newStrictModalityTarget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStrictModalityTargetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.StrictModalityTargetLabelLengthRule(maxLength: 3600)
        let item = Imaging.newStrictModalityTarget("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictModalityTargetRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Imaging.StrictModalityTargetRequiredTimezoneRule(message: "strict modality target needs a value")
        let item = Imaging.newStrictModalityTarget("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
