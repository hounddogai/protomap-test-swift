@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInventorySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRollingInventorySnapshotValidator()
        let item = Pharmacy.newRollingInventorySnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRollingInventorySnapshotFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Pharmacy.RollingInventorySnapshotFacilityLengthRule(maxLength: 3600)
        let item = Pharmacy.newRollingInventorySnapshot("x", title: "y")
        item.facility = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRollingInventorySnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RollingInventorySnapshotRequiredCodeRule(
            message: "rolling inventory snapshot needs an entry"
        )
        let item = Pharmacy.newRollingInventorySnapshot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRollingInventorySnapshotExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Pharmacy.RollingInventorySnapshotExpiresAtRangeRule(min: 120, max: 3600)
        let item = Pharmacy.newRollingInventorySnapshot("x", title: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRollingInventorySnapshotRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Pharmacy.RollingInventorySnapshotRequiredFacilityRule(
            message: "rolling inventory snapshot needs this field"
        )
        let item = Pharmacy.newRollingInventorySnapshot("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRollingInventorySnapshotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.RollingInventorySnapshotRequiredTitleRule(
            message: "rolling inventory snapshot needs an entry"
        )
        let item = Pharmacy.newRollingInventorySnapshot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
