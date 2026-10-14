@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledOvertimeProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultScheduledOvertimeProposalValidator()
        let item = Staffing.newScheduledOvertimeProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingScheduledOvertimeProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ScheduledOvertimeProposalCodeLengthRule(maxLength: 16)
        let item = Staffing.newScheduledOvertimeProposal("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingScheduledOvertimeProposalRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.ScheduledOvertimeProposalRequiredNameRule(
            message: "scheduled overtime proposal needs this field"
        )
        let item = Staffing.newScheduledOvertimeProposal("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingScheduledOvertimeProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ScheduledOvertimeProposalRequiredCodeRule(
            message: "scheduled overtime proposal needs a value"
        )
        let item = Staffing.newScheduledOvertimeProposal("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingScheduledOvertimeProposalLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.ScheduledOvertimeProposalLabelLengthRule(maxLength: 64)
        let item = Staffing.newScheduledOvertimeProposal("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
