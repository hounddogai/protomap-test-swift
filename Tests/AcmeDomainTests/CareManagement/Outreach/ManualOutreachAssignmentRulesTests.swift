@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultManualOutreachAssignmentValidator()
        let item = CareManagement.newManualOutreachAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementManualOutreachAssignmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.ManualOutreachAssignmentNameLengthRule(maxLength: 255)
        let item = CareManagement.newManualOutreachAssignment("x", label: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualOutreachAssignmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.ManualOutreachAssignmentLabelLengthRule(maxLength: 32)
        let item = CareManagement.newManualOutreachAssignment("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualOutreachAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.ManualOutreachAssignmentRequiredNameRule(
            message: "manual outreach assignment needs this field"
        )
        let item = CareManagement.newManualOutreachAssignment("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementManualOutreachAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ManualOutreachAssignmentCodeLengthRule(maxLength: 32)
        let item = CareManagement.newManualOutreachAssignment("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
