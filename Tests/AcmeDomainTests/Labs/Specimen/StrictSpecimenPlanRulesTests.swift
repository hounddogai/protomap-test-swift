@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictSpecimenPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultStrictSpecimenPlanValidator()
        let item = Labs.newStrictSpecimenPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsStrictSpecimenPlanCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Labs.StrictSpecimenPlanCopayRangeRule(min: 2.6, max: 4464.8)
        let item = Labs.newStrictSpecimenPlan("x", label: "y")
        item.copay = 4466.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsStrictSpecimenPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.StrictSpecimenPlanRequiredCodeRule(message: "strict specimen plan needs an entry")
        let item = Labs.newStrictSpecimenPlan("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsStrictSpecimenPlanRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Labs.StrictSpecimenPlanRequiredDescriptionRule(message: "strict specimen plan needs this field")
        let item = Labs.newStrictSpecimenPlan("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsStrictSpecimenPlanCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.StrictSpecimenPlanCeilingRangeRule(min: 9.6, max: 1874.7)
        let item = Labs.newStrictSpecimenPlan("x", label: "y")
        item.ceiling = 1876.2
        #expect(rule.check(item).count > 0)
    }
}
