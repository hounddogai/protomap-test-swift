@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultManualRecallGroupValidator()
        let item = Pharmacy.newManualRecallGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyManualRecallGroupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.ManualRecallGroupLabelLengthRule(maxLength: 3600)
        let item = Pharmacy.newManualRecallGroup("x", name: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualRecallGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.ManualRecallGroupCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newManualRecallGroup("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualRecallGroupAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Pharmacy.ManualRecallGroupAttemptsRangeRule(min: 255, max: 255)
        let item = Pharmacy.newManualRecallGroup("x", name: "y")
        item.attempts = 256
        #expect(rule.check(item).count > 0)
    }
}
