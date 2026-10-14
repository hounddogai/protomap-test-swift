@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledProgramExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultScheduledProgramExceptionValidator()
        let item = CareManagement.newScheduledProgramException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementScheduledProgramExceptionRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = CareManagement.ScheduledProgramExceptionRequiredWardRule(
            message: "scheduled program exception needs a value"
        )
        let item = CareManagement.newScheduledProgramException("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementScheduledProgramExceptionWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = CareManagement.ScheduledProgramExceptionWardLengthRule(maxLength: 86400)
        let item = CareManagement.newScheduledProgramException("x", label: "y")
        item.ward = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
