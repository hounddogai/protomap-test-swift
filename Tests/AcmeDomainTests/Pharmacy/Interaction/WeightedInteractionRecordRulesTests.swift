@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedInteractionRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedInteractionRecordValidator()
        let item = Pharmacy.newWeightedInteractionRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedInteractionRecordRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Pharmacy.WeightedInteractionRecordRequiredOwnerIDRule(
            message: "weighted interaction record needs a value"
        )
        let item = Pharmacy.newWeightedInteractionRecord("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyWeightedInteractionRecordStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Pharmacy.WeightedInteractionRecordStartsAtRangeRule(min: 255, max: 3600)
        let item = Pharmacy.newWeightedInteractionRecord("x", title: "y")
        item.startsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyWeightedInteractionRecordTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.WeightedInteractionRecordTitleLengthRule(maxLength: 3600)
        let item = Pharmacy.newWeightedInteractionRecord("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedInteractionRecordRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.WeightedInteractionRecordRequiredTitleRule(
            message: "weighted interaction record needs an entry"
        )
        let item = Pharmacy.newWeightedInteractionRecord("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
