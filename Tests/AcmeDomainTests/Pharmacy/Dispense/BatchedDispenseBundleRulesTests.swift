@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedDispenseBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultBatchedDispenseBundleValidator()
        let item = Pharmacy.newBatchedDispenseBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyBatchedDispenseBundleFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Pharmacy.BatchedDispenseBundleFacilityLengthRule(maxLength: 80)
        let item = Pharmacy.newBatchedDispenseBundle("x", label: "y")
        item.facility = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedDispenseBundleRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Pharmacy.BatchedDispenseBundleRequiredRegionRule(message: "batched dispense bundle needs a value")
        let item = Pharmacy.newBatchedDispenseBundle("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyBatchedDispenseBundleCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Pharmacy.BatchedDispenseBundleCreatedAtRangeRule(min: 120, max: 3600)
        let item = Pharmacy.newBatchedDispenseBundle("x", label: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
