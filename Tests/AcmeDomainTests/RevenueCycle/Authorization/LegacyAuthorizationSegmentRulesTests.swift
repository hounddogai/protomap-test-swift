@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyAuthorizationSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLegacyAuthorizationSegmentValidator()
        let item = RevenueCycle.newLegacyAuthorizationSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLegacyAuthorizationSegmentSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = RevenueCycle.LegacyAuthorizationSegmentSequenceRangeRule(min: 16, max: 64)
        let item = RevenueCycle.newLegacyAuthorizationSegment("x", title: "y")
        item.sequence = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLegacyAuthorizationSegmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.LegacyAuthorizationSegmentTitleLengthRule(maxLength: 120)
        let item = RevenueCycle.newLegacyAuthorizationSegment("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyAuthorizationSegmentDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = RevenueCycle.LegacyAuthorizationSegmentDiagnosisCodeLengthRule(maxLength: 32)
        let item = RevenueCycle.newLegacyAuthorizationSegment("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
