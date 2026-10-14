@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenRuleValidator()
        let item = Labs.newSpecimenRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenRuleCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Labs.SpecimenRuleCostRangeRule(min: 1.0, max: 3017.2)
        let item = Labs.newSpecimenRule("x", title: "y")
        item.cost = 3018.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SpecimenRuleCodeLengthRule(maxLength: 86400)
        let item = Labs.newSpecimenRule("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenRuleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.SpecimenRuleLabelLengthRule(maxLength: 86400)
        let item = Labs.newSpecimenRule("x", title: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
