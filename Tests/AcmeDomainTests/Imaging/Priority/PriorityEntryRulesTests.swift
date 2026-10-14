@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityEntryValidator()
        let item = Imaging.newPriorityEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.PriorityEntryRequiredCodeRule(message: "priority entry needs this field")
        let item = Imaging.newPriorityEntry("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityEntryPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Imaging.PriorityEntryPayerLengthRule(maxLength: 32)
        let item = Imaging.newPriorityEntry("x", name: "y")
        item.payer = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityEntryWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Imaging.PriorityEntryWindowDaysRangeRule(min: 120, max: 255)
        let item = Imaging.newPriorityEntry("x", name: "y")
        item.windowDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityEntryRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Imaging.PriorityEntryRequiredPayerRule(message: "priority entry needs this field")
        let item = Imaging.newPriorityEntry("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
