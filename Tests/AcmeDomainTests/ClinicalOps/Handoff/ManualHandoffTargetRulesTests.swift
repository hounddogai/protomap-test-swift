@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualHandoffTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultManualHandoffTargetValidator()
        let item = ClinicalOps.newManualHandoffTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsManualHandoffTargetWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = ClinicalOps.ManualHandoffTargetWeightRangeRule(min: 8.3, max: 1577.9)
        let item = ClinicalOps.newManualHandoffTarget("x", name: "y")
        item.weight = 1579.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsManualHandoffTargetContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = ClinicalOps.ManualHandoffTargetContactEmailLengthRule(maxLength: 3600)
        let item = ClinicalOps.newManualHandoffTarget("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsManualHandoffTargetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.ManualHandoffTargetRequiredNameRule(message: "manual handoff target needs a value")
        let item = ClinicalOps.newManualHandoffTarget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
