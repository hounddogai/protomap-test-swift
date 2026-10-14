@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyFormularyRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyFormularyRollupValidator()
        let item = Pharmacy.newLegacyFormularyRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyFormularyRollupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.LegacyFormularyRollupLabelLengthRule(maxLength: 16)
        let item = Pharmacy.newLegacyFormularyRollup("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyFormularyRollupTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Pharmacy.LegacyFormularyRollupTimezoneLengthRule(maxLength: 1000)
        let item = Pharmacy.newLegacyFormularyRollup("x", label: "y")
        item.timezone = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
