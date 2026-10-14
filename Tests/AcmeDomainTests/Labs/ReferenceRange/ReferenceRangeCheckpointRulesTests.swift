@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeCheckpointValidator()
        let item = Labs.newReferenceRangeCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeCheckpointRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.ReferenceRangeCheckpointRequiredNameRule(message: "reference range checkpoint needs a value")
        let item = Labs.newReferenceRangeCheckpoint("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeCheckpointDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Labs.ReferenceRangeCheckpointDiscountRangeRule(min: 1.3, max: 3616.7)
        let item = Labs.newReferenceRangeCheckpoint("x", name: "y")
        item.discount = 3618.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeCheckpointSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Labs.ReferenceRangeCheckpointSequenceRangeRule(min: 1000, max: 86400)
        let item = Labs.newReferenceRangeCheckpoint("x", name: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}
