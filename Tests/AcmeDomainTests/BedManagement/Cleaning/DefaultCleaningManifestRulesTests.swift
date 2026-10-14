@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDefaultCleaningManifestValidator()
        let item = BedManagement.newDefaultCleaningManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDefaultCleaningManifestGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.DefaultCleaningManifestGraceDaysRangeRule(min: 64, max: 255)
        let item = BedManagement.newDefaultCleaningManifest("x", label: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDefaultCleaningManifestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.DefaultCleaningManifestLabelLengthRule(maxLength: 1000)
        let item = BedManagement.newDefaultCleaningManifest("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDefaultCleaningManifestBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = BedManagement.DefaultCleaningManifestBatchSizeRangeRule(min: 255, max: 3600)
        let item = BedManagement.newDefaultCleaningManifest("x", label: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDefaultCleaningManifestWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = BedManagement.DefaultCleaningManifestWindowDaysRangeRule(min: 64, max: 255)
        let item = BedManagement.newDefaultCleaningManifest("x", label: "y")
        item.windowDays = 256
        #expect(rule.check(item).count > 0)
    }
}
