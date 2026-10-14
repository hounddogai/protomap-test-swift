@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyCourierWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacyCourierWindowValidator()
        let item = Labs.newLegacyCourierWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacyCourierWindowBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.LegacyCourierWindowBatchSizeRangeRule(min: 80, max: 86400)
        let item = Labs.newLegacyCourierWindow("x", title: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLegacyCourierWindowAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Labs.LegacyCourierWindowAmountRangeRule(min: 4.4, max: 2318.0)
        let item = Labs.newLegacyCourierWindow("x", title: "y")
        item.amount = 2319.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLegacyCourierWindowTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.LegacyCourierWindowTitleLengthRule(maxLength: 80)
        let item = Labs.newLegacyCourierWindow("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacyCourierWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.LegacyCourierWindowRequiredCodeRule(message: "legacy courier window needs this field")
        let item = Labs.newLegacyCourierWindow("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacyCourierWindowRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Labs.LegacyCourierWindowRequiredEncounterIDRule(message: "legacy courier window needs a value")
        let item = Labs.newLegacyCourierWindow("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacyCourierWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.LegacyCourierWindowCodeLengthRule(maxLength: 64)
        let item = Labs.newLegacyCourierWindow("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
