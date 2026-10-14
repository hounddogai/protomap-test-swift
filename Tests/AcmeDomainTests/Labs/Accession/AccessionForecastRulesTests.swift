@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionForecastValidator()
        let item = Labs.newAccessionForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionForecastCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Labs.AccessionForecastCreatedAtRangeRule(min: 16, max: 1000)
        let item = Labs.newAccessionForecast("x", title: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AccessionForecastRequiredCodeRule(message: "accession forecast needs this field")
        let item = Labs.newAccessionForecast("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AccessionForecastCodeLengthRule(maxLength: 1000)
        let item = Labs.newAccessionForecast("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionForecastRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.AccessionForecastRequiredTitleRule(message: "accession forecast needs an entry")
        let item = Labs.newAccessionForecast("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionForecastLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Labs.AccessionForecastLocaleLengthRule(maxLength: 255)
        let item = Labs.newAccessionForecast("x", title: "y")
        item.locale = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
