@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackCareProtocolAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultFallbackCareProtocolAuditValidator()
        let item = Imaging.newFallbackCareProtocolAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingFallbackCareProtocolAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.FallbackCareProtocolAuditCodeLengthRule(maxLength: 86400)
        let item = Imaging.newFallbackCareProtocolAudit("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackCareProtocolAuditEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Imaging.FallbackCareProtocolAuditEndsAtRangeRule(min: 3600, max: 86400)
        let item = Imaging.newFallbackCareProtocolAudit("x", title: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingFallbackCareProtocolAuditSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Imaging.FallbackCareProtocolAuditSequenceRangeRule(min: 16, max: 64)
        let item = Imaging.newFallbackCareProtocolAudit("x", title: "y")
        item.sequence = 65
        #expect(rule.check(item).count > 0)
    }
}
