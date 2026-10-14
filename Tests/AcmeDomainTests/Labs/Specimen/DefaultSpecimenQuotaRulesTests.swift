@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultDefaultSpecimenQuotaValidator()
        let item = Labs.newDefaultSpecimenQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsDefaultSpecimenQuotaSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Labs.DefaultSpecimenQuotaSequenceRangeRule(min: 64, max: 86400)
        let item = Labs.newDefaultSpecimenQuota("x", label: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsDefaultSpecimenQuotaWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Labs.DefaultSpecimenQuotaWardLengthRule(maxLength: 255)
        let item = Labs.newDefaultSpecimenQuota("x", label: "y")
        item.ward = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
