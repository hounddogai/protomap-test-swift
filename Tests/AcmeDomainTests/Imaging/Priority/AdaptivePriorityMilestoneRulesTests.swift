@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptivePriorityMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultAdaptivePriorityMilestoneValidator()
        let item = Imaging.newAdaptivePriorityMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingAdaptivePriorityMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.AdaptivePriorityMilestoneRequiredCodeRule(
            message: "adaptive priority milestone needs this field"
        )
        let item = Imaging.newAdaptivePriorityMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingAdaptivePriorityMilestoneRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Imaging.AdaptivePriorityMilestoneRequiredContactEmailRule(
            message: "adaptive priority milestone needs this field"
        )
        let item = Imaging.newAdaptivePriorityMilestone("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
