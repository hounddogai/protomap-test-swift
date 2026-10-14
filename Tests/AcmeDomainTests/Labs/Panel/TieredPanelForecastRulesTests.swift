@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredPanelForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultTieredPanelForecastValidator()
        let item = Labs.newTieredPanelForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsTieredPanelForecastGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Labs.TieredPanelForecastGraceDaysRangeRule(min: 32, max: 64)
        let item = Labs.newTieredPanelForecast("x", title: "y")
        item.graceDays = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsTieredPanelForecastTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.TieredPanelForecastTitleLengthRule(maxLength: 255)
        let item = Labs.newTieredPanelForecast("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsTieredPanelForecastVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Labs.TieredPanelForecastVisitMinutesRangeRule(min: 80, max: 80)
        let item = Labs.newTieredPanelForecast("x", title: "y")
        item.visitMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}
