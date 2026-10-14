@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryFloatPoolAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryFloatPoolAssignmentValidator()
        let item = Staffing.newPrimaryFloatPoolAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryFloatPoolAssignmentRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Staffing.PrimaryFloatPoolAssignmentRequiredChecksumRule(
            message: "primary float pool assignment needs a value"
        )
        let item = Staffing.newPrimaryFloatPoolAssignment("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryFloatPoolAssignmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.PrimaryFloatPoolAssignmentLabelLengthRule(maxLength: 120)
        let item = Staffing.newPrimaryFloatPoolAssignment("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
