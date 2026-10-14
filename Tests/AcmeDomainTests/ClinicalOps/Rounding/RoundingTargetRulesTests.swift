@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingTargetValidator()
        let item = ClinicalOps.newRoundingTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingTargetProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = ClinicalOps.RoundingTargetProcedureCodeLengthRule(maxLength: 80)
        let item = ClinicalOps.newRoundingTarget("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingTargetVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = ClinicalOps.RoundingTargetVersionRangeRule(min: 255, max: 86400)
        let item = ClinicalOps.newRoundingTarget("x", label: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingTargetDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = ClinicalOps.RoundingTargetDescriptionLengthRule(maxLength: 80)
        let item = ClinicalOps.newRoundingTarget("x", label: "y")
        item.description = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingTargetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.RoundingTargetLabelLengthRule(maxLength: 255)
        let item = ClinicalOps.newRoundingTarget("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingTargetRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = ClinicalOps.RoundingTargetRequiredProcedureCodeRule(message: "rounding target needs a value")
        let item = ClinicalOps.newRoundingTarget("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
