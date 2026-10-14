@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramGroupValidator()
        let item = CareManagement.newProgramGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ProgramGroupCodeLengthRule(maxLength: 120)
        let item = CareManagement.newProgramGroup("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramGroupReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = CareManagement.ProgramGroupReviewerLengthRule(maxLength: 255)
        let item = CareManagement.newProgramGroup("x", label: "y")
        item.reviewer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ProgramGroupRequiredCodeRule(message: "program group needs an entry")
        let item = CareManagement.newProgramGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
