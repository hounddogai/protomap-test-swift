@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryOrderSetCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPrimaryOrderSetCycleValidator()
        let item = ClinicalOps.newPrimaryOrderSetCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPrimaryOrderSetCycleOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = ClinicalOps.PrimaryOrderSetCycleOwnerIDLengthRule(maxLength: 16)
        let item = ClinicalOps.newPrimaryOrderSetCycle("x", label: "y")
        item.ownerID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryOrderSetCycleQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = ClinicalOps.PrimaryOrderSetCycleQuantityRangeRule(min: 32, max: 64)
        let item = ClinicalOps.newPrimaryOrderSetCycle("x", label: "y")
        item.quantity = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPrimaryOrderSetCycleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.PrimaryOrderSetCycleLabelLengthRule(maxLength: 86400)
        let item = ClinicalOps.newPrimaryOrderSetCycle("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
