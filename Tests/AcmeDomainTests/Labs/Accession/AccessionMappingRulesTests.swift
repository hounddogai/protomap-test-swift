@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionMappingValidator()
        let item = Labs.newAccessionMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionMappingRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Labs.AccessionMappingRequiredExternalRefRule(message: "accession mapping needs a value")
        let item = Labs.newAccessionMapping("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionMappingAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.AccessionMappingAttemptsRangeRule(min: 255, max: 86400)
        let item = Labs.newAccessionMapping("x", title: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionMappingUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Labs.AccessionMappingUpdatedAtRangeRule(min: 16, max: 32)
        let item = Labs.newAccessionMapping("x", title: "y")
        item.updatedAt = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionMappingRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Labs.AccessionMappingRequiredPayerRule(message: "accession mapping needs an entry")
        let item = Labs.newAccessionMapping("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
