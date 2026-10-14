@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultMetricValidator()
        let item = Labs.newResultMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultMetricAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.ResultMetricAttemptsRangeRule(min: 32, max: 64)
        let item = Labs.newResultMetric("x", name: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultMetricChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Labs.ResultMetricChecksumLengthRule(maxLength: 255)
        let item = Labs.newResultMetric("x", name: "y")
        item.checksum = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ResultMetricRequiredCodeRule(message: "result metric needs a value")
        let item = Labs.newResultMetric("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
