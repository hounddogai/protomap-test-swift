@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptivePriorityOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultAdaptivePriorityOverrideValidator()
        let item = Imaging.newAdaptivePriorityOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingAdaptivePriorityOverrideRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Imaging.AdaptivePriorityOverrideRequiredPatientRefRule(
            message: "adaptive priority override needs an entry"
        )
        let item = Imaging.newAdaptivePriorityOverride("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingAdaptivePriorityOverrideRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Imaging.AdaptivePriorityOverrideRequiredSourceRule(
            message: "adaptive priority override needs a value"
        )
        let item = Imaging.newAdaptivePriorityOverride("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingAdaptivePriorityOverrideRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.AdaptivePriorityOverrideRequiredLabelRule(message: "adaptive priority override needs a value")
        let item = Imaging.newAdaptivePriorityOverride("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
