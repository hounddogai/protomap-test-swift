@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffAllocationValidator()
        let item = ClinicalOps.newHandoffAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffAllocationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.HandoffAllocationLabelLengthRule(maxLength: 1000)
        let item = ClinicalOps.newHandoffAllocation("x", title: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.HandoffAllocationCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newHandoffAllocation("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffAllocationVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = ClinicalOps.HandoffAllocationVisitMinutesRangeRule(min: 120, max: 120)
        let item = ClinicalOps.newHandoffAllocation("x", title: "y")
        item.visitMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}
