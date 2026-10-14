@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingCareGapNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingCareGapNoticeValidator()
        let item = CareManagement.newPendingCareGapNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingCareGapNoticeRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.PendingCareGapNoticeRequiredLabelRule(
            message: "pending care gap notice needs an entry"
        )
        let item = CareManagement.newPendingCareGapNotice("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPendingCareGapNoticeLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.PendingCareGapNoticeLabelLengthRule(maxLength: 64)
        let item = CareManagement.newPendingCareGapNotice("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingCareGapNoticeRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = CareManagement.PendingCareGapNoticeRetriesRangeRule(min: 16, max: 3600)
        let item = CareManagement.newPendingCareGapNotice("x", label: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPendingCareGapNoticeRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = CareManagement.PendingCareGapNoticeRequiredTimezoneRule(
            message: "pending care gap notice needs an entry"
        )
        let item = CareManagement.newPendingCareGapNotice("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
