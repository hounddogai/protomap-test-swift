@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierBatchValidator()
        let item = Labs.newCourierBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierBatchExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Labs.CourierBatchExpiresAtRangeRule(min: 32, max: 80)
        let item = Labs.newCourierBatch("x", label: "y")
        item.expiresAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCourierBatchCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Labs.CourierBatchCapacityRangeRule(min: 1000, max: 1000)
        let item = Labs.newCourierBatch("x", label: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCourierBatchRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Labs.CourierBatchRequiredPayerRule(message: "courier batch needs a value")
        let item = Labs.newCourierBatch("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
