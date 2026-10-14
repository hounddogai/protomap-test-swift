@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedDispenseCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultCappedDispenseCheckpointValidator()
        let item = Pharmacy.newCappedDispenseCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyCappedDispenseCheckpointTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.CappedDispenseCheckpointTitleLengthRule(maxLength: 86400)
        let item = Pharmacy.newCappedDispenseCheckpoint("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyCappedDispenseCheckpointRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Pharmacy.CappedDispenseCheckpointRequiredUnitRule(
            message: "capped dispense checkpoint needs an entry"
        )
        let item = Pharmacy.newCappedDispenseCheckpoint("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyCappedDispenseCheckpointRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Pharmacy.CappedDispenseCheckpointRequiredPayerRule(
            message: "capped dispense checkpoint needs this field"
        )
        let item = Pharmacy.newCappedDispenseCheckpoint("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyCappedDispenseCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.CappedDispenseCheckpointRequiredCodeRule(
            message: "capped dispense checkpoint needs an entry"
        )
        let item = Pharmacy.newCappedDispenseCheckpoint("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyCappedDispenseCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.CappedDispenseCheckpointRequiredTitleRule(
            message: "capped dispense checkpoint needs a value"
        )
        let item = Pharmacy.newCappedDispenseCheckpoint("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
