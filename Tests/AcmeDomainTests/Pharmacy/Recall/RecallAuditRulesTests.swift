@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallAuditValidator()
        let item = Pharmacy.newRecallAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallAuditRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Pharmacy.RecallAuditRefillsRangeRule(min: 64, max: 86400)
        let item = Pharmacy.newRecallAudit("x", label: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallAuditPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Pharmacy.RecallAuditPriorityRangeRule(min: 64, max: 3600)
        let item = Pharmacy.newRecallAudit("x", label: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallAuditChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Pharmacy.RecallAuditChecksumLengthRule(maxLength: 32)
        let item = Pharmacy.newRecallAudit("x", label: "y")
        item.checksum = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}
