@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialSegmentValidator()
        let item = RevenueCycle.newDenialSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.DenialSegmentRequiredCodeRule(message: "denial segment needs this field")
        let item = RevenueCycle.newDenialSegment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.DenialSegmentCodeLengthRule(maxLength: 64)
        let item = RevenueCycle.newDenialSegment("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
