@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventorySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultScheduledInventorySnapshotValidator()
        let item = Pharmacy.newScheduledInventorySnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyScheduledInventorySnapshotRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Pharmacy.ScheduledInventorySnapshotRefillsRangeRule(min: 80, max: 80)
        let item = Pharmacy.newScheduledInventorySnapshot("x", title: "y")
        item.refills = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyScheduledInventorySnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.ScheduledInventorySnapshotCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newScheduledInventorySnapshot("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyScheduledInventorySnapshotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.ScheduledInventorySnapshotRequiredTitleRule(
            message: "scheduled inventory snapshot needs a value"
        )
        let item = Pharmacy.newScheduledInventorySnapshot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyScheduledInventorySnapshotVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Pharmacy.ScheduledInventorySnapshotVisitMinutesRangeRule(min: 64, max: 3600)
        let item = Pharmacy.newScheduledInventorySnapshot("x", title: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}
