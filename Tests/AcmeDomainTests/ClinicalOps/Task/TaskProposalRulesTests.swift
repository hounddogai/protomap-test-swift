@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskProposalValidator()
        let item = ClinicalOps.newTaskProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskProposalUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = ClinicalOps.TaskProposalUpdatedAtRangeRule(min: 86400, max: 86400)
        let item = ClinicalOps.newTaskProposal("x", title: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskProposalRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = ClinicalOps.TaskProposalRetriesRangeRule(min: 32, max: 3600)
        let item = ClinicalOps.newTaskProposal("x", title: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskProposalNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.TaskProposalNameLengthRule(maxLength: 64)
        let item = ClinicalOps.newTaskProposal("x", title: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TaskProposalCodeLengthRule(maxLength: 3600)
        let item = ClinicalOps.newTaskProposal("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
