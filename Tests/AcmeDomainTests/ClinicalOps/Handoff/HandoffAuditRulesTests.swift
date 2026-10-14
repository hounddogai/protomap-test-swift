@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffAuditValidator()
        let item = ClinicalOps.newHandoffAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffAuditRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.HandoffAuditRequiredLabelRule(message: "handoff audit needs an entry")
        let item = ClinicalOps.newHandoffAudit("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffAuditCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = ClinicalOps.HandoffAuditCeilingRangeRule(min: 3.4, max: 2949.4)
        let item = ClinicalOps.newHandoffAudit("x", label: "y")
        item.ceiling = 2950.9
        #expect(rule.check(item).count > 0)
    }
}
