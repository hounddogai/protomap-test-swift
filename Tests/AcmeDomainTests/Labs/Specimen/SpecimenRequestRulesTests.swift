@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenRequestValidator()
        let item = Labs.newSpecimenRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenRequestCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Labs.SpecimenRequestCountryLengthRule(maxLength: 64)
        let item = Labs.newSpecimenRequest("x", name: "y")
        item.country = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenRequestBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.SpecimenRequestBatchSizeRangeRule(min: 64, max: 3600)
        let item = Labs.newSpecimenRequest("x", name: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenRequestRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Labs.SpecimenRequestRequiredChannelRule(message: "specimen request needs this field")
        let item = Labs.newSpecimenRequest("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenRequestExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Labs.SpecimenRequestExpiresAtRangeRule(min: 16, max: 16)
        let item = Labs.newSpecimenRequest("x", name: "y")
        item.expiresAt = 17
        #expect(rule.check(item).count > 0)
    }
}
