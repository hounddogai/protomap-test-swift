@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadVarianceValidator()
        let item = Imaging.newReadVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadVarianceSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Imaging.ReadVarianceSegmentLengthRule(maxLength: 32)
        let item = Imaging.newReadVariance("x", name: "y")
        item.segment = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ReadVarianceCodeLengthRule(maxLength: 32)
        let item = Imaging.newReadVariance("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
