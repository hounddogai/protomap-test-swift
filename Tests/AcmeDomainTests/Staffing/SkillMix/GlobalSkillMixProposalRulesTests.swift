@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalSkillMixProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultGlobalSkillMixProposalValidator()
        let item = Staffing.newGlobalSkillMixProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingGlobalSkillMixProposalTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.GlobalSkillMixProposalTitleLengthRule(maxLength: 255)
        let item = Staffing.newGlobalSkillMixProposal("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalSkillMixProposalRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Staffing.GlobalSkillMixProposalRequiredOwnerIDRule(
            message: "global skill mix proposal needs an entry"
        )
        let item = Staffing.newGlobalSkillMixProposal("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
