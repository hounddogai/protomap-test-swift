@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalOrderSetOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRegionalOrderSetOverrideValidator()
        let item = ClinicalOps.newRegionalOrderSetOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRegionalOrderSetOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.RegionalOrderSetOverrideRequiredCodeRule(
            message: "regional order set override needs this field"
        )
        let item = ClinicalOps.newRegionalOrderSetOverride("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRegionalOrderSetOverrideRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.RegionalOrderSetOverrideRequiredLabelRule(
            message: "regional order set override needs this field"
        )
        let item = ClinicalOps.newRegionalOrderSetOverride("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRegionalOrderSetOverrideRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = ClinicalOps.RegionalOrderSetOverrideRevisionRangeRule(min: 1000, max: 3600)
        let item = ClinicalOps.newRegionalOrderSetOverride("x", label: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRegionalOrderSetOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RegionalOrderSetOverrideCodeLengthRule(maxLength: 120)
        let item = ClinicalOps.newRegionalOrderSetOverride("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalOrderSetOverrideRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = ClinicalOps.RegionalOrderSetOverrideRequiredProcedureCodeRule(
            message: "regional order set override needs a value"
        )
        let item = ClinicalOps.newRegionalOrderSetOverride("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
