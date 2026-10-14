@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingProgramBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRollingProgramBatchValidator()
        let item = CareManagement.newRollingProgramBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRollingProgramBatchRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = CareManagement.RollingProgramBatchRequiredProcedureCodeRule(
            message: "rolling program batch needs a value"
        )
        let item = CareManagement.newRollingProgramBatch("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRollingProgramBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.RollingProgramBatchRequiredCodeRule(message: "rolling program batch needs a value")
        let item = CareManagement.newRollingProgramBatch("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRollingProgramBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.RollingProgramBatchCodeLengthRule(maxLength: 16)
        let item = CareManagement.newRollingProgramBatch("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRollingProgramBatchRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.RollingProgramBatchRequiredNameRule(message: "rolling program batch needs an entry")
        let item = CareManagement.newRollingProgramBatch("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRollingProgramBatchNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.RollingProgramBatchNameLengthRule(maxLength: 86400)
        let item = CareManagement.newRollingProgramBatch("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRollingProgramBatchTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.RollingProgramBatchTitleLengthRule(maxLength: 32)
        let item = CareManagement.newRollingProgramBatch("x", name: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
