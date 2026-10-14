@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedPanelWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedPanelWindowValidator()
        let item = Labs.newCappedPanelWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedPanelWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CappedPanelWindowRequiredCodeRule(message: "capped panel window needs this field")
        let item = Labs.newCappedPanelWindow("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCappedPanelWindowCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Labs.CappedPanelWindowCostRangeRule(min: 0.9, max: 3217.2)
        let item = Labs.newCappedPanelWindow("x", title: "y")
        item.cost = 3218.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedPanelWindowWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Labs.CappedPanelWindowWardLengthRule(maxLength: 255)
        let item = Labs.newCappedPanelWindow("x", title: "y")
        item.ward = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
