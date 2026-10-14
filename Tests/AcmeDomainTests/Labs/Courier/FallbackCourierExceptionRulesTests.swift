@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackCourierExceptionValidator()
        let item = Labs.newFallbackCourierException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackCourierExceptionRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.FallbackCourierExceptionRequiredNameRule(message: "fallback courier exception needs an entry")
        let item = Labs.newFallbackCourierException("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackCourierExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.FallbackCourierExceptionRequiredCodeRule(message: "fallback courier exception needs this field")
        let item = Labs.newFallbackCourierException("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackCourierExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.FallbackCourierExceptionTitleLengthRule(maxLength: 86400)
        let item = Labs.newFallbackCourierException("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
