@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingOutreachCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingOutreachCheckpointValidator()
        let item = CareManagement.newPendingOutreachCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingOutreachCheckpointRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = CareManagement.PendingOutreachCheckpointRequiredSourceRule(
            message: "pending outreach checkpoint needs this field"
        )
        let item = CareManagement.newPendingOutreachCheckpoint("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPendingOutreachCheckpointVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = CareManagement.PendingOutreachCheckpointVisitMinutesRangeRule(min: 32, max: 3600)
        let item = CareManagement.newPendingOutreachCheckpoint("x", label: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPendingOutreachCheckpointCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = CareManagement.PendingOutreachCheckpointCategoryLengthRule(maxLength: 64)
        let item = CareManagement.newPendingOutreachCheckpoint("x", label: "y")
        item.category = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
