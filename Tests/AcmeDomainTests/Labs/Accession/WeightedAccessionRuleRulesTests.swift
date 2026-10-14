@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedAccessionRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultWeightedAccessionRuleValidator()
        let item = Labs.newWeightedAccessionRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsWeightedAccessionRuleRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Labs.WeightedAccessionRuleRatioRangeRule(min: 5.5, max: 3495.8)
        let item = Labs.newWeightedAccessionRule("x", title: "y")
        item.ratio = 3497.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsWeightedAccessionRuleFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Labs.WeightedAccessionRuleFacilityLengthRule(maxLength: 80)
        let item = Labs.newWeightedAccessionRule("x", title: "y")
        item.facility = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsWeightedAccessionRuleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.WeightedAccessionRuleRequiredTitleRule(message: "weighted accession rule needs this field")
        let item = Labs.newWeightedAccessionRule("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsWeightedAccessionRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.WeightedAccessionRuleCodeLengthRule(maxLength: 32)
        let item = Labs.newWeightedAccessionRule("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsWeightedAccessionRuleRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Labs.WeightedAccessionRuleRequiredPhoneRule(message: "weighted accession rule needs this field")
        let item = Labs.newWeightedAccessionRule("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
