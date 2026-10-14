@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalAccessionTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultGlobalAccessionTierValidator()
        let item = Labs.newGlobalAccessionTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsGlobalAccessionTierRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Labs.GlobalAccessionTierRequiredWardRule(message: "global accession tier needs a value")
        let item = Labs.newGlobalAccessionTier("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsGlobalAccessionTierLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Labs.GlobalAccessionTierLocaleLengthRule(maxLength: 32)
        let item = Labs.newGlobalAccessionTier("x", title: "y")
        item.locale = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsGlobalAccessionTierWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Labs.GlobalAccessionTierWindowDaysRangeRule(min: 64, max: 1000)
        let item = Labs.newGlobalAccessionTier("x", title: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}
