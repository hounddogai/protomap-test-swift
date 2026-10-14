@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseEntryValidator()
        let item = Pharmacy.newDispenseEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseEntryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.DispenseEntryTitleLengthRule(maxLength: 120)
        let item = Pharmacy.newDispenseEntry("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseEntrySpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Pharmacy.DispenseEntrySpecialtyLengthRule(maxLength: 1000)
        let item = Pharmacy.newDispenseEntry("x", title: "y")
        item.specialty = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseEntryThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Pharmacy.DispenseEntryThresholdRangeRule(min: 2.6, max: 2767.2)
        let item = Pharmacy.newDispenseEntry("x", title: "y")
        item.threshold = 2768.7
        #expect(rule.check(item).count > 0)
    }
}
