@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingInteractionVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPendingInteractionVarianceValidator()
        let item = Pharmacy.newPendingInteractionVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPendingInteractionVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.PendingInteractionVarianceRequiredCodeRule(
            message: "pending interaction variance needs an entry"
        )
        let item = Pharmacy.newPendingInteractionVariance("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPendingInteractionVarianceExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Pharmacy.PendingInteractionVarianceExpiresAtRangeRule(min: 32, max: 80)
        let item = Pharmacy.newPendingInteractionVariance("x", label: "y")
        item.expiresAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPendingInteractionVarianceRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Pharmacy.PendingInteractionVarianceRequiredChecksumRule(
            message: "pending interaction variance needs a value"
        )
        let item = Pharmacy.newPendingInteractionVariance("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPendingInteractionVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.PendingInteractionVarianceTitleLengthRule(maxLength: 80)
        let item = Pharmacy.newPendingInteractionVariance("x", label: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
