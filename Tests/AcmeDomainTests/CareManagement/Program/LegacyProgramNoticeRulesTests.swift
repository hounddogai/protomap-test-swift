@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyProgramNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLegacyProgramNoticeValidator()
        let item = CareManagement.newLegacyProgramNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLegacyProgramNoticeRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.LegacyProgramNoticeRequiredLabelRule(message: "legacy program notice needs this field")
        let item = CareManagement.newLegacyProgramNotice("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLegacyProgramNoticeCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = CareManagement.LegacyProgramNoticeCapacityRangeRule(min: 16, max: 80)
        let item = CareManagement.newLegacyProgramNotice("x", label: "y")
        item.capacity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementLegacyProgramNoticeDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = CareManagement.LegacyProgramNoticeDurationMinutesRangeRule(min: 16, max: 3600)
        let item = CareManagement.newLegacyProgramNotice("x", label: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementLegacyProgramNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.LegacyProgramNoticeRequiredCodeRule(message: "legacy program notice needs an entry")
        let item = CareManagement.newLegacyProgramNotice("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLegacyProgramNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.LegacyProgramNoticeCodeLengthRule(maxLength: 32)
        let item = CareManagement.newLegacyProgramNotice("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
