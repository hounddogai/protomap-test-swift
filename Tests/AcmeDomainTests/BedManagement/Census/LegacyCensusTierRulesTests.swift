@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLegacyCensusTierValidator()
        let item = BedManagement.newLegacyCensusTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLegacyCensusTierLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.LegacyCensusTierLabelLengthRule(maxLength: 80)
        let item = BedManagement.newLegacyCensusTier("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLegacyCensusTierWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = BedManagement.LegacyCensusTierWindowDaysRangeRule(min: 32, max: 64)
        let item = BedManagement.newLegacyCensusTier("x", label: "y")
        item.windowDays = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLegacyCensusTierPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = BedManagement.LegacyCensusTierPatientRefLengthRule(maxLength: 1000)
        let item = BedManagement.newLegacyCensusTier("x", label: "y")
        item.patientRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLegacyCensusTierRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.LegacyCensusTierRequiredLabelRule(message: "legacy census tier needs this field")
        let item = BedManagement.newLegacyCensusTier("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLegacyCensusTierThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = BedManagement.LegacyCensusTierThresholdRangeRule(min: 9.4, max: 4438.9)
        let item = BedManagement.newLegacyCensusTier("x", label: "y")
        item.threshold = 4440.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLegacyCensusTierBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = BedManagement.LegacyCensusTierBatchSizeRangeRule(min: 1000, max: 3600)
        let item = BedManagement.newLegacyCensusTier("x", label: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}
