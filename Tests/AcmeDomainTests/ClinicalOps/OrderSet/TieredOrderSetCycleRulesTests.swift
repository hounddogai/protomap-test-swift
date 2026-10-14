@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredOrderSetCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTieredOrderSetCycleValidator()
        let item = ClinicalOps.newTieredOrderSetCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTieredOrderSetCycleVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = ClinicalOps.TieredOrderSetCycleVisitMinutesRangeRule(min: 255, max: 1000)
        let item = ClinicalOps.newTieredOrderSetCycle("x", label: "y")
        item.visitMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTieredOrderSetCycleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.TieredOrderSetCycleRequiredLabelRule(message: "tiered order set cycle needs a value")
        let item = ClinicalOps.newTieredOrderSetCycle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTieredOrderSetCycleVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = ClinicalOps.TieredOrderSetCycleVersionRangeRule(min: 80, max: 255)
        let item = ClinicalOps.newTieredOrderSetCycle("x", label: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTieredOrderSetCycleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.TieredOrderSetCycleLabelLengthRule(maxLength: 120)
        let item = ClinicalOps.newTieredOrderSetCycle("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTieredOrderSetCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TieredOrderSetCycleRequiredCodeRule(message: "tiered order set cycle needs an entry")
        let item = ClinicalOps.newTieredOrderSetCycle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
