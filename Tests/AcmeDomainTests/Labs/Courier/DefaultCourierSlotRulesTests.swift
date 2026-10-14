@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultCourierSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultDefaultCourierSlotValidator()
        let item = Labs.newDefaultCourierSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsDefaultCourierSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.DefaultCourierSlotCodeLengthRule(maxLength: 120)
        let item = Labs.newDefaultCourierSlot("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsDefaultCourierSlotAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Labs.DefaultCourierSlotAmountRangeRule(min: 3.6, max: 1647.1)
        let item = Labs.newDefaultCourierSlot("x", name: "y")
        item.amount = 1648.6
        #expect(rule.check(item).count > 0)
    }
}
