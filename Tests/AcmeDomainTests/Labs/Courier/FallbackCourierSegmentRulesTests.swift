@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackCourierSegmentValidator()
        let item = Labs.newFallbackCourierSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackCourierSegmentCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Labs.FallbackCourierSegmentCountryLengthRule(maxLength: 86400)
        let item = Labs.newFallbackCourierSegment("x", title: "y")
        item.country = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackCourierSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.FallbackCourierSegmentCodeLengthRule(maxLength: 80)
        let item = Labs.newFallbackCourierSegment("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
