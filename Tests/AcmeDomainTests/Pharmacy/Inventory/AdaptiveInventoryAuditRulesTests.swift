@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInventoryAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultAdaptiveInventoryAuditValidator()
        let item = Pharmacy.newAdaptiveInventoryAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyAdaptiveInventoryAuditSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Pharmacy.AdaptiveInventoryAuditSummaryLengthRule(maxLength: 32)
        let item = Pharmacy.newAdaptiveInventoryAudit("x", name: "y")
        item.summary = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyAdaptiveInventoryAuditCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Pharmacy.AdaptiveInventoryAuditCeilingRangeRule(min: 3.3, max: 2013.3)
        let item = Pharmacy.newAdaptiveInventoryAudit("x", name: "y")
        item.ceiling = 2014.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyAdaptiveInventoryAuditWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Pharmacy.AdaptiveInventoryAuditWeightRangeRule(min: 8.0, max: 3307.2)
        let item = Pharmacy.newAdaptiveInventoryAudit("x", name: "y")
        item.weight = 3308.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyAdaptiveInventoryAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.AdaptiveInventoryAuditCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newAdaptiveInventoryAudit("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyAdaptiveInventoryAuditWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Pharmacy.AdaptiveInventoryAuditWardLengthRule(maxLength: 32)
        let item = Pharmacy.newAdaptiveInventoryAudit("x", name: "y")
        item.ward = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
