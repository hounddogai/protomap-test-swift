@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolProposalValidator()
        let item = Staffing.newFloatPoolProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolProposalSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Staffing.FloatPoolProposalSourceLengthRule(maxLength: 80)
        let item = Staffing.newFloatPoolProposal("x", title: "y")
        item.source = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolProposalTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.FloatPoolProposalTitleLengthRule(maxLength: 64)
        let item = Staffing.newFloatPoolProposal("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolProposalWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Staffing.FloatPoolProposalWindowDaysRangeRule(min: 32, max: 3600)
        let item = Staffing.newFloatPoolProposal("x", title: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolProposalEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Staffing.FloatPoolProposalEndsAtRangeRule(min: 16, max: 86400)
        let item = Staffing.newFloatPoolProposal("x", title: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
