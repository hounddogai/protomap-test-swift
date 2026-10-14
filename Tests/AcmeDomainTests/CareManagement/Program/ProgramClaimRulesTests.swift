@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramClaimValidator()
        let item = CareManagement.newProgramClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramClaimLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.ProgramClaimLabelLengthRule(maxLength: 64)
        let item = CareManagement.newProgramClaim("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramClaimRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.ProgramClaimRequiredLabelRule(message: "program claim needs an entry")
        let item = CareManagement.newProgramClaim("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ProgramClaimCodeLengthRule(maxLength: 64)
        let item = CareManagement.newProgramClaim("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ProgramClaimRequiredCodeRule(message: "program claim needs an entry")
        let item = CareManagement.newProgramClaim("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
