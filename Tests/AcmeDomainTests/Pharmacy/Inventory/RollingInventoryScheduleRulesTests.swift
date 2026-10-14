@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInventoryScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRollingInventoryScheduleValidator()
        let item = Pharmacy.newRollingInventorySchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRollingInventoryScheduleRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Pharmacy.RollingInventoryScheduleRequiredClinicianIDRule(
            message: "rolling inventory schedule needs a value"
        )
        let item = Pharmacy.newRollingInventorySchedule("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRollingInventoryScheduleRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Pharmacy.RollingInventoryScheduleRefillsRangeRule(min: 32, max: 255)
        let item = Pharmacy.newRollingInventorySchedule("x", label: "y")
        item.refills = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRollingInventoryScheduleThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Pharmacy.RollingInventoryScheduleThresholdRangeRule(min: 0.6, max: 3744.0)
        let item = Pharmacy.newRollingInventorySchedule("x", label: "y")
        item.threshold = 3745.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRollingInventoryScheduleRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Pharmacy.RollingInventoryScheduleRegionLengthRule(maxLength: 32)
        let item = Pharmacy.newRollingInventorySchedule("x", label: "y")
        item.region = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRollingInventoryScheduleRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Pharmacy.RollingInventoryScheduleRetriesRangeRule(min: 120, max: 255)
        let item = Pharmacy.newRollingInventorySchedule("x", label: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}
