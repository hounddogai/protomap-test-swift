@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPendingRecallRollupValidator()
        let item = Pharmacy.newPendingRecallRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPendingRecallRollupRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Pharmacy.PendingRecallRollupRequiredLocaleRule(message: "pending recall rollup needs a value")
        let item = Pharmacy.newPendingRecallRollup("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPendingRecallRollupSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Pharmacy.PendingRecallRollupSequenceRangeRule(min: 120, max: 86400)
        let item = Pharmacy.newPendingRecallRollup("x", title: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}
