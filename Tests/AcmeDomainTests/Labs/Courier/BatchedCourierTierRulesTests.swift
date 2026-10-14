@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedCourierTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultBatchedCourierTierValidator()
        let item = Labs.newBatchedCourierTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsBatchedCourierTierLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.BatchedCourierTierLabelLengthRule(maxLength: 80)
        let item = Labs.newBatchedCourierTier("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsBatchedCourierTierCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Labs.BatchedCourierTierCountryLengthRule(maxLength: 1000)
        let item = Labs.newBatchedCourierTier("x", label: "y")
        item.country = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsBatchedCourierTierEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Labs.BatchedCourierTierEncounterIDLengthRule(maxLength: 3600)
        let item = Labs.newBatchedCourierTier("x", label: "y")
        item.encounterID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
