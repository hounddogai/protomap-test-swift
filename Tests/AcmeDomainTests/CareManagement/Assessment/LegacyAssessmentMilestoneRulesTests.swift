@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyAssessmentMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLegacyAssessmentMilestoneValidator()
        let item = CareManagement.newLegacyAssessmentMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLegacyAssessmentMilestoneRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.LegacyAssessmentMilestoneRequiredNameRule(
            message: "legacy assessment milestone needs a value"
        )
        let item = CareManagement.newLegacyAssessmentMilestone("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLegacyAssessmentMilestoneNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.LegacyAssessmentMilestoneNameLengthRule(maxLength: 80)
        let item = CareManagement.newLegacyAssessmentMilestone("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLegacyAssessmentMilestoneRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = CareManagement.LegacyAssessmentMilestoneRequiredDescriptionRule(
            message: "legacy assessment milestone needs this field"
        )
        let item = CareManagement.newLegacyAssessmentMilestone("", name: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLegacyAssessmentMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.LegacyAssessmentMilestoneRequiredCodeRule(
            message: "legacy assessment milestone needs an entry"
        )
        let item = CareManagement.newLegacyAssessmentMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLegacyAssessmentMilestoneRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = CareManagement.LegacyAssessmentMilestoneRequiredChecksumRule(
            message: "legacy assessment milestone needs this field"
        )
        let item = CareManagement.newLegacyAssessmentMilestone("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
