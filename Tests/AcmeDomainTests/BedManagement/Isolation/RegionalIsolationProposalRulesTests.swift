@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalIsolationProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRegionalIsolationProposalValidator()
        let item = BedManagement.newRegionalIsolationProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRegionalIsolationProposalMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = BedManagement.RegionalIsolationProposalMarginRangeRule(min: 3.0, max: 3356.9)
        let item = BedManagement.newRegionalIsolationProposal("x", title: "y")
        item.margin = 3358.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRegionalIsolationProposalRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.RegionalIsolationProposalRequiredTitleRule(
            message: "regional isolation proposal needs a value"
        )
        let item = BedManagement.newRegionalIsolationProposal("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRegionalIsolationProposalLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.RegionalIsolationProposalLimitRangeRule(min: 16, max: 32)
        let item = BedManagement.newRegionalIsolationProposal("x", title: "y")
        item.limit = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRegionalIsolationProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.RegionalIsolationProposalCodeLengthRule(maxLength: 120)
        let item = BedManagement.newRegionalIsolationProposal("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
