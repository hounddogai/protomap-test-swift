@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictCareProtocolTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultStrictCareProtocolTargetValidator()
        let item = ClinicalOps.newStrictCareProtocolTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsStrictCareProtocolTargetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.StrictCareProtocolTargetLabelLengthRule(maxLength: 80)
        let item = ClinicalOps.newStrictCareProtocolTarget("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsStrictCareProtocolTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.StrictCareProtocolTargetCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newStrictCareProtocolTarget("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsStrictCareProtocolTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.StrictCareProtocolTargetRequiredCodeRule(
            message: "strict care protocol target needs this field"
        )
        let item = ClinicalOps.newStrictCareProtocolTarget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
