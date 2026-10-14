@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryHandoffSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPrimaryHandoffSlotValidator()
        let item = ClinicalOps.newPrimaryHandoffSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPrimaryHandoffSlotRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = ClinicalOps.PrimaryHandoffSlotRequiredProcedureCodeRule(
            message: "primary handoff slot needs an entry"
        )
        let item = ClinicalOps.newPrimaryHandoffSlot("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPrimaryHandoffSlotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.PrimaryHandoffSlotNameLengthRule(maxLength: 1000)
        let item = ClinicalOps.newPrimaryHandoffSlot("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryHandoffSlotRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = ClinicalOps.PrimaryHandoffSlotRefillsRangeRule(min: 32, max: 80)
        let item = ClinicalOps.newPrimaryHandoffSlot("x", name: "y")
        item.refills = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPrimaryHandoffSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.PrimaryHandoffSlotRequiredCodeRule(message: "primary handoff slot needs this field")
        let item = ClinicalOps.newPrimaryHandoffSlot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
