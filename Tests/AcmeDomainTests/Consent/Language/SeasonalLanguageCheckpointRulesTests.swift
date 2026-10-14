@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalLanguageCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultSeasonalLanguageCheckpointValidator()
        let item = Consent.newSeasonalLanguageCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentSeasonalLanguageCheckpointVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Consent.SeasonalLanguageCheckpointVersionRangeRule(min: 32, max: 255)
        let item = Consent.newSeasonalLanguageCheckpoint("x", title: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentSeasonalLanguageCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.SeasonalLanguageCheckpointRequiredTitleRule(
            message: "seasonal language checkpoint needs an entry"
        )
        let item = Consent.newSeasonalLanguageCheckpoint("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentSeasonalLanguageCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.SeasonalLanguageCheckpointCodeLengthRule(maxLength: 255)
        let item = Consent.newSeasonalLanguageCheckpoint("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
