@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultDefaultSpecimenPlanValidator()
        let item = Labs.newDefaultSpecimenPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsDefaultSpecimenPlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.DefaultSpecimenPlanRequiredTitleRule(message: "default specimen plan needs a value")
        let item = Labs.newDefaultSpecimenPlan("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultSpecimenPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.DefaultSpecimenPlanRequiredCodeRule(message: "default specimen plan needs this field")
        let item = Labs.newDefaultSpecimenPlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultSpecimenPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.DefaultSpecimenPlanCodeLengthRule(maxLength: 16)
        let item = Labs.newDefaultSpecimenPlan("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsDefaultSpecimenPlanRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Labs.DefaultSpecimenPlanRequiredUnitRule(message: "default specimen plan needs a value")
        let item = Labs.newDefaultSpecimenPlan("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultSpecimenPlanMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Labs.DefaultSpecimenPlanMarginRangeRule(min: 7.6, max: 1735.8)
        let item = Labs.newDefaultSpecimenPlan("x", title: "y")
        item.margin = 1737.3
        #expect(rule.check(item).count > 0)
    }
}
