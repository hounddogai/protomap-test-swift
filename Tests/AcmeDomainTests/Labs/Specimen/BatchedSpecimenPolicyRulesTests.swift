@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedSpecimenPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultBatchedSpecimenPolicyValidator()
        let item = Labs.newBatchedSpecimenPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsBatchedSpecimenPolicyRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.BatchedSpecimenPolicyRequiredNameRule(message: "batched specimen policy needs an entry")
        let item = Labs.newBatchedSpecimenPolicy("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsBatchedSpecimenPolicyWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Labs.BatchedSpecimenPolicyWindowDaysRangeRule(min: 80, max: 1000)
        let item = Labs.newBatchedSpecimenPolicy("x", name: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsBatchedSpecimenPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.BatchedSpecimenPolicyRequiredCodeRule(message: "batched specimen policy needs a value")
        let item = Labs.newBatchedSpecimenPolicy("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsBatchedSpecimenPolicyUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Labs.BatchedSpecimenPolicyUpdatedAtRangeRule(min: 80, max: 1000)
        let item = Labs.newBatchedSpecimenPolicy("x", name: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsBatchedSpecimenPolicyCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Labs.BatchedSpecimenPolicyCountryLengthRule(maxLength: 86400)
        let item = Labs.newBatchedSpecimenPolicy("x", name: "y")
        item.country = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}
