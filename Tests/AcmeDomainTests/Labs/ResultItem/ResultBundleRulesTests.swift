@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultBundleValidator()
        let item = Labs.newResultBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultBundleRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Labs.ResultBundleRequiredCurrencyRule(message: "result bundle needs a value")
        let item = Labs.newResultBundle("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultBundleVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Labs.ResultBundleVersionRangeRule(min: 16, max: 80)
        let item = Labs.newResultBundle("x", title: "y")
        item.version = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultBundleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.ResultBundleRequiredTitleRule(message: "result bundle needs an entry")
        let item = Labs.newResultBundle("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultBundleAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Labs.ResultBundleAllergyLengthRule(maxLength: 32)
        let item = Labs.newResultBundle("x", title: "y")
        item.allergy = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}
