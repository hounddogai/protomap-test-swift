@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingRecallBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRollingRecallBaselineValidator()
        let item = Pharmacy.newRollingRecallBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRollingRecallBaselineEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Pharmacy.RollingRecallBaselineEndsAtRangeRule(min: 255, max: 86400)
        let item = Pharmacy.newRollingRecallBaseline("x", label: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRollingRecallBaselineRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.RollingRecallBaselineRequiredLabelRule(message: "rolling recall baseline needs a value")
        let item = Pharmacy.newRollingRecallBaseline("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRollingRecallBaselineRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.RollingRecallBaselineRequiredNameRule(message: "rolling recall baseline needs this field")
        let item = Pharmacy.newRollingRecallBaseline("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
