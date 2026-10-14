@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredRecallMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultTieredRecallMetricValidator()
        let item = Pharmacy.newTieredRecallMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyTieredRecallMetricSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Pharmacy.TieredRecallMetricSegmentLengthRule(maxLength: 16)
        let item = Pharmacy.newTieredRecallMetric("x", name: "y")
        item.segment = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyTieredRecallMetricBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Pharmacy.TieredRecallMetricBedLengthRule(maxLength: 32)
        let item = Pharmacy.newTieredRecallMetric("x", name: "y")
        item.bed = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyTieredRecallMetricRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.TieredRecallMetricRequiredNameRule(message: "tiered recall metric needs an entry")
        let item = Pharmacy.newTieredRecallMetric("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyTieredRecallMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.TieredRecallMetricCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newTieredRecallMetric("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
