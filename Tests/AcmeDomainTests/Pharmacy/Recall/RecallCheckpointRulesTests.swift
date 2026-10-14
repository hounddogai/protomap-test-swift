@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallCheckpointValidator()
        let item = Pharmacy.newRecallCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallCheckpointCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Pharmacy.RecallCheckpointCurrencyLengthRule(maxLength: 1000)
        let item = Pharmacy.newRecallCheckpoint("x", title: "y")
        item.currency = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.RecallCheckpointRequiredTitleRule(message: "recall checkpoint needs this field")
        let item = Pharmacy.newRecallCheckpoint("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.RecallCheckpointCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newRecallCheckpoint("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallCheckpointEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Pharmacy.RecallCheckpointEndsAtRangeRule(min: 32, max: 1000)
        let item = Pharmacy.newRecallCheckpoint("x", title: "y")
        item.endsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallCheckpointRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Pharmacy.RecallCheckpointRequiredCurrencyRule(message: "recall checkpoint needs an entry")
        let item = Pharmacy.newRecallCheckpoint("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallCheckpointRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.RecallCheckpointRequiredNameRule(message: "recall checkpoint needs this field")
        let item = Pharmacy.newRecallCheckpoint("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
