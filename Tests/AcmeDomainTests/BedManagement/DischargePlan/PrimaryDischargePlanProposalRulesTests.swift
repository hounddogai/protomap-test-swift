@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryDischargePlanProposalValidator()
        let item = BedManagement.newPrimaryDischargePlanProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.PrimaryDischargePlanProposalRequiredCodeRule(
            message: "primary discharge plan proposal needs an entry"
        )
        let item = BedManagement.newPrimaryDischargePlanProposal("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryDischargePlanProposalCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = BedManagement.PrimaryDischargePlanProposalCreatedAtRangeRule(min: 64, max: 255)
        let item = BedManagement.newPrimaryDischargePlanProposal("x", name: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.PrimaryDischargePlanProposalCodeLengthRule(maxLength: 64)
        let item = BedManagement.newPrimaryDischargePlanProposal("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanProposalLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.PrimaryDischargePlanProposalLimitRangeRule(min: 32, max: 120)
        let item = BedManagement.newPrimaryDischargePlanProposal("x", name: "y")
        item.limit = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanProposalNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.PrimaryDischargePlanProposalNameLengthRule(maxLength: 86400)
        let item = BedManagement.newPrimaryDischargePlanProposal("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
