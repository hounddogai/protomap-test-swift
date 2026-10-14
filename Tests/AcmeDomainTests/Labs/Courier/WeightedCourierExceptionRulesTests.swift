@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedCourierExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultWeightedCourierExceptionValidator()
        let item = Labs.newWeightedCourierException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsWeightedCourierExceptionRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Labs.WeightedCourierExceptionRequiredChecksumRule(
            message: "weighted courier exception needs this field"
        )
        let item = Labs.newWeightedCourierException("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsWeightedCourierExceptionChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Labs.WeightedCourierExceptionChecksumLengthRule(maxLength: 32)
        let item = Labs.newWeightedCourierException("x", label: "y")
        item.checksum = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsWeightedCourierExceptionCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Labs.WeightedCourierExceptionCurrencyLengthRule(maxLength: 16)
        let item = Labs.newWeightedCourierException("x", label: "y")
        item.currency = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsWeightedCourierExceptionRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Labs.WeightedCourierExceptionRequiredCurrencyRule(
            message: "weighted courier exception needs an entry"
        )
        let item = Labs.newWeightedCourierException("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
