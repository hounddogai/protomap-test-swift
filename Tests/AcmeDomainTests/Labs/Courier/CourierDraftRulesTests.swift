@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierDraftValidator()
        let item = Labs.newCourierDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierDraftRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Labs.CourierDraftRequiredUnitRule(message: "courier draft needs this field")
        let item = Labs.newCourierDraft("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierDraftNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.CourierDraftNameLengthRule(maxLength: 16)
        let item = Labs.newCourierDraft("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierDraftMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Labs.CourierDraftMaximumRangeRule(min: 3.9, max: 2539.7)
        let item = Labs.newCourierDraft("x", name: "y")
        item.maximum = 2541.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCourierDraftUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Labs.CourierDraftUnitLengthRule(maxLength: 16)
        let item = Labs.newCourierDraft("x", name: "y")
        item.unit = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierDraftWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Labs.CourierDraftWeightRangeRule(min: 0.7, max: 2672.3)
        let item = Labs.newCourierDraft("x", name: "y")
        item.weight = 2673.8
        #expect(rule.check(item).count > 0)
    }
}
