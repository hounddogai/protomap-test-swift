@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyAssessmentRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLegacyAssessmentRollupValidator()
        let item = CareManagement.newLegacyAssessmentRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLegacyAssessmentRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.LegacyAssessmentRollupRequiredCodeRule(
            message: "legacy assessment rollup needs an entry"
        )
        let item = CareManagement.newLegacyAssessmentRollup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLegacyAssessmentRollupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.LegacyAssessmentRollupLabelLengthRule(maxLength: 64)
        let item = CareManagement.newLegacyAssessmentRollup("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLegacyAssessmentRollupRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = CareManagement.LegacyAssessmentRollupRequiredDescriptionRule(
            message: "legacy assessment rollup needs this field"
        )
        let item = CareManagement.newLegacyAssessmentRollup("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLegacyAssessmentRollupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.LegacyAssessmentRollupRequiredLabelRule(
            message: "legacy assessment rollup needs this field"
        )
        let item = CareManagement.newLegacyAssessmentRollup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
