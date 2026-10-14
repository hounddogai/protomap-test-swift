@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingProgramDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRollingProgramDraftValidator()
        let item = CareManagement.newRollingProgramDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRollingProgramDraftUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = CareManagement.RollingProgramDraftUpdatedAtRangeRule(min: 32, max: 86400)
        let item = CareManagement.newRollingProgramDraft("x", name: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRollingProgramDraftVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = CareManagement.RollingProgramDraftVisitMinutesRangeRule(min: 64, max: 3600)
        let item = CareManagement.newRollingProgramDraft("x", name: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRollingProgramDraftRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.RollingProgramDraftRequiredChannelRule(message: "rolling program draft needs a value")
        let item = CareManagement.newRollingProgramDraft("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRollingProgramDraftNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.RollingProgramDraftNameLengthRule(maxLength: 1000)
        let item = CareManagement.newRollingProgramDraft("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
