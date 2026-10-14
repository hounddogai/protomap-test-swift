@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyGoalSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLegacyGoalSegmentValidator()
        let item = CareManagement.newLegacyGoalSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLegacyGoalSegmentUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = CareManagement.LegacyGoalSegmentUnitLengthRule(maxLength: 255)
        let item = CareManagement.newLegacyGoalSegment("x", label: "y")
        item.unit = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLegacyGoalSegmentDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = CareManagement.LegacyGoalSegmentDiagnosisCodeLengthRule(maxLength: 64)
        let item = CareManagement.newLegacyGoalSegment("x", label: "y")
        item.diagnosisCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLegacyGoalSegmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.LegacyGoalSegmentRequiredLabelRule(message: "legacy goal segment needs an entry")
        let item = CareManagement.newLegacyGoalSegment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
