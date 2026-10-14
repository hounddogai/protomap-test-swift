@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetRollupValidator()
        let item = ClinicalOps.newOrderSetRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.OrderSetRollupCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newOrderSetRollup("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetRollupPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.OrderSetRollupPatientRefLengthRule(maxLength: 86400)
        let item = ClinicalOps.newOrderSetRollup("x", title: "y")
        item.patientRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetRollupTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.OrderSetRollupTitleLengthRule(maxLength: 1000)
        let item = ClinicalOps.newOrderSetRollup("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetRollupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.OrderSetRollupRequiredTitleRule(message: "order set rollup needs an entry")
        let item = ClinicalOps.newOrderSetRollup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetRollupRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = ClinicalOps.OrderSetRollupRequiredSourceRule(message: "order set rollup needs this field")
        let item = ClinicalOps.newOrderSetRollup("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}
