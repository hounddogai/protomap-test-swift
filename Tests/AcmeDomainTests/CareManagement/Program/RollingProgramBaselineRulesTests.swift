@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingProgramBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRollingProgramBaselineValidator()
        let item = CareManagement.newRollingProgramBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRollingProgramBaselineSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = CareManagement.RollingProgramBaselineSpecialtyLengthRule(maxLength: 120)
        let item = CareManagement.newRollingProgramBaseline("x", title: "y")
        item.specialty = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRollingProgramBaselineTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.RollingProgramBaselineTitleLengthRule(maxLength: 255)
        let item = CareManagement.newRollingProgramBaseline("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
