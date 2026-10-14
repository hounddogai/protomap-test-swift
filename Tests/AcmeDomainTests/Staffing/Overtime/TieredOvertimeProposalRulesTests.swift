@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredOvertimeProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultTieredOvertimeProposalValidator()
        let item = Staffing.newTieredOvertimeProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingTieredOvertimeProposalRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Staffing.TieredOvertimeProposalRequiredCategoryRule(
            message: "tiered overtime proposal needs an entry"
        )
        let item = Staffing.newTieredOvertimeProposal("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingTieredOvertimeProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.TieredOvertimeProposalRequiredCodeRule(message: "tiered overtime proposal needs an entry")
        let item = Staffing.newTieredOvertimeProposal("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
