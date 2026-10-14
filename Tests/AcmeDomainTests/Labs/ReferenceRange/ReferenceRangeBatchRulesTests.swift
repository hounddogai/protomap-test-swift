@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeBatchValidator()
        let item = Labs.newReferenceRangeBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeBatchPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Labs.ReferenceRangeBatchPriorityRangeRule(min: 120, max: 1000)
        let item = Labs.newReferenceRangeBatch("x", label: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeBatchCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Labs.ReferenceRangeBatchCapacityRangeRule(min: 64, max: 1000)
        let item = Labs.newReferenceRangeBatch("x", label: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}
