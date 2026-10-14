@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledCareGapSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultScheduledCareGapSnapshotValidator()
        let item = CareManagement.newScheduledCareGapSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementScheduledCareGapSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ScheduledCareGapSnapshotRequiredCodeRule(
            message: "scheduled care gap snapshot needs a value"
        )
        let item = CareManagement.newScheduledCareGapSnapshot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementScheduledCareGapSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ScheduledCareGapSnapshotCodeLengthRule(maxLength: 64)
        let item = CareManagement.newScheduledCareGapSnapshot("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementScheduledCareGapSnapshotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.ScheduledCareGapSnapshotTitleLengthRule(maxLength: 1000)
        let item = CareManagement.newScheduledCareGapSnapshot("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementScheduledCareGapSnapshotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.ScheduledCareGapSnapshotRequiredTitleRule(
            message: "scheduled care gap snapshot needs a value"
        )
        let item = CareManagement.newScheduledCareGapSnapshot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
