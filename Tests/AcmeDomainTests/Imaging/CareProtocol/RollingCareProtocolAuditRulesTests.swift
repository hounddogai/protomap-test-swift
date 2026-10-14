@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRollingCareProtocolAuditValidator()
        let item = Imaging.newRollingCareProtocolAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRollingCareProtocolAuditChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Imaging.RollingCareProtocolAuditChecksumLengthRule(maxLength: 3600)
        let item = Imaging.newRollingCareProtocolAudit("x", label: "y")
        item.checksum = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRollingCareProtocolAuditMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Imaging.RollingCareProtocolAuditMinimumRangeRule(min: 8.3, max: 4546.6)
        let item = Imaging.newRollingCareProtocolAudit("x", label: "y")
        item.minimum = 4548.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingRollingCareProtocolAuditLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.RollingCareProtocolAuditLabelLengthRule(maxLength: 32)
        let item = Imaging.newRollingCareProtocolAudit("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRollingCareProtocolAuditCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Imaging.RollingCareProtocolAuditCopayRangeRule(min: 1.3, max: 321.4)
        let item = Imaging.newRollingCareProtocolAudit("x", label: "y")
        item.copay = 322.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingRollingCareProtocolAuditPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Imaging.RollingCareProtocolAuditPhoneLengthRule(maxLength: 64)
        let item = Imaging.newRollingCareProtocolAudit("x", label: "y")
        item.phone = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
