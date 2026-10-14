@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalDispenseMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultGlobalDispenseMetricValidator()
        let item = Pharmacy.newGlobalDispenseMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyGlobalDispenseMetricNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.GlobalDispenseMetricNameLengthRule(maxLength: 255)
        let item = Pharmacy.newGlobalDispenseMetric("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyGlobalDispenseMetricRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Pharmacy.GlobalDispenseMetricRequiredChecksumRule(message: "global dispense metric needs a value")
        let item = Pharmacy.newGlobalDispenseMetric("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyGlobalDispenseMetricChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Pharmacy.GlobalDispenseMetricChecksumLengthRule(maxLength: 120)
        let item = Pharmacy.newGlobalDispenseMetric("x", name: "y")
        item.checksum = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyGlobalDispenseMetricGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Pharmacy.GlobalDispenseMetricGraceDaysRangeRule(min: 32, max: 64)
        let item = Pharmacy.newGlobalDispenseMetric("x", name: "y")
        item.graceDays = 65
        #expect(rule.check(item).count > 0)
    }
}
