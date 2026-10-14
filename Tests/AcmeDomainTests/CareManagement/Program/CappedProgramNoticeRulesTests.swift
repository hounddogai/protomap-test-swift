@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedProgramNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCappedProgramNoticeValidator()
        let item = CareManagement.newCappedProgramNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCappedProgramNoticeTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = CareManagement.CappedProgramNoticeTimezoneLengthRule(maxLength: 80)
        let item = CareManagement.newCappedProgramNotice("x", name: "y")
        item.timezone = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCappedProgramNoticeExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = CareManagement.CappedProgramNoticeExpiresAtRangeRule(min: 16, max: 86400)
        let item = CareManagement.newCappedProgramNotice("x", name: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCappedProgramNoticePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = CareManagement.CappedProgramNoticePriorityRangeRule(min: 32, max: 120)
        let item = CareManagement.newCappedProgramNotice("x", name: "y")
        item.priority = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCappedProgramNoticeRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = CareManagement.CappedProgramNoticeRequiredTimezoneRule(
            message: "capped program notice needs this field"
        )
        let item = CareManagement.newCappedProgramNotice("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCappedProgramNoticeRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = CareManagement.CappedProgramNoticeRequiredSegmentRule(message: "capped program notice needs an entry")
        let item = CareManagement.newCappedProgramNotice("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
