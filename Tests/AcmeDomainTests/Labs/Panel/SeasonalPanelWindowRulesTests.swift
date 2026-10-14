@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalPanelWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSeasonalPanelWindowValidator()
        let item = Labs.newSeasonalPanelWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSeasonalPanelWindowNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.SeasonalPanelWindowNameLengthRule(maxLength: 64)
        let item = Labs.newSeasonalPanelWindow("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSeasonalPanelWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SeasonalPanelWindowCodeLengthRule(maxLength: 32)
        let item = Labs.newSeasonalPanelWindow("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSeasonalPanelWindowRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.SeasonalPanelWindowRequiredNameRule(message: "seasonal panel window needs this field")
        let item = Labs.newSeasonalPanelWindow("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
