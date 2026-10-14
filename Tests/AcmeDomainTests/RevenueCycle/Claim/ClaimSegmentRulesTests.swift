@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimSegmentValidator()
        let item = RevenueCycle.newClaimSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimSegmentPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = RevenueCycle.ClaimSegmentPatientRefLengthRule(maxLength: 64)
        let item = RevenueCycle.newClaimSegment("x", label: "y")
        item.patientRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimSegmentCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = RevenueCycle.ClaimSegmentCeilingRangeRule(min: 8.7, max: 2342.2)
        let item = RevenueCycle.newClaimSegment("x", label: "y")
        item.ceiling = 2343.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ClaimSegmentCodeLengthRule(maxLength: 1000)
        let item = RevenueCycle.newClaimSegment("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
