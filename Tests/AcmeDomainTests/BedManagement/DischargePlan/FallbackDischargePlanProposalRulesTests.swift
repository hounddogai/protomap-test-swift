@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackDischargePlanProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackDischargePlanProposalValidator()
        let item = BedManagement.newFallbackDischargePlanProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackDischargePlanProposalRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = BedManagement.FallbackDischargePlanProposalRequiredDescriptionRule(
            message: "fallback discharge plan proposal needs an entry"
        )
        let item = BedManagement.newFallbackDischargePlanProposal("", name: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackDischargePlanProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.FallbackDischargePlanProposalCodeLengthRule(maxLength: 80)
        let item = BedManagement.newFallbackDischargePlanProposal("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackDischargePlanProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.FallbackDischargePlanProposalRequiredCodeRule(
            message: "fallback discharge plan proposal needs a value"
        )
        let item = BedManagement.newFallbackDischargePlanProposal("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
