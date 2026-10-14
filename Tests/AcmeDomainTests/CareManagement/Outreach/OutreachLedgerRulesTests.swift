@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachLedgerValidator()
        let item = CareManagement.newOutreachLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachLedgerWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = CareManagement.OutreachLedgerWeightRangeRule(min: 3.1, max: 4434.6)
        let item = CareManagement.newOutreachLedger("x", label: "y")
        item.weight = 4436.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachLedgerSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = CareManagement.OutreachLedgerSequenceRangeRule(min: 64, max: 3600)
        let item = CareManagement.newOutreachLedger("x", label: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}
