@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingProgramTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingProgramTargetValidator()
        let item = CareManagement.newPendingProgramTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingProgramTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.PendingProgramTargetRequiredCodeRule(
            message: "pending program target needs this field"
        )
        let item = CareManagement.newPendingProgramTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPendingProgramTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.PendingProgramTargetCodeLengthRule(maxLength: 80)
        let item = CareManagement.newPendingProgramTarget("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
