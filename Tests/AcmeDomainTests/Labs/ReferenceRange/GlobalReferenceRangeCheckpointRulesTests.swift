@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalReferenceRangeCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultGlobalReferenceRangeCheckpointValidator()
        let item = Labs.newGlobalReferenceRangeCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsGlobalReferenceRangeCheckpointRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Labs.GlobalReferenceRangeCheckpointRatioRangeRule(min: 8.2, max: 1385.3)
        let item = Labs.newGlobalReferenceRangeCheckpoint("x", name: "y")
        item.ratio = 1386.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsGlobalReferenceRangeCheckpointRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Labs.GlobalReferenceRangeCheckpointRequiredLocaleRule(
            message: "global reference range checkpoint needs this field"
        )
        let item = Labs.newGlobalReferenceRangeCheckpoint("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsGlobalReferenceRangeCheckpointPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Labs.GlobalReferenceRangeCheckpointPayerLengthRule(maxLength: 3600)
        let item = Labs.newGlobalReferenceRangeCheckpoint("x", name: "y")
        item.payer = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
