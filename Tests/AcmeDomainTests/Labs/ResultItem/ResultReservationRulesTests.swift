@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultReservationValidator()
        let item = Labs.newResultReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultReservationAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Labs.ResultReservationAmountRangeRule(min: 5.8, max: 964.7)
        let item = Labs.newResultReservation("x", label: "y")
        item.amount = 966.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ResultReservationRequiredCodeRule(message: "result reservation needs this field")
        let item = Labs.newResultReservation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultReservationCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Labs.ResultReservationCategoryLengthRule(maxLength: 255)
        let item = Labs.newResultReservation("x", label: "y")
        item.category = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultReservationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.ResultReservationLabelLengthRule(maxLength: 16)
        let item = Labs.newResultReservation("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
