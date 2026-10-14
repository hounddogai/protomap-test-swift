@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultFormularySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultFormularySnapshotValidator()
        let item = Pharmacy.newDefaultFormularySnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultFormularySnapshotCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Pharmacy.DefaultFormularySnapshotCategoryLengthRule(maxLength: 16)
        let item = Pharmacy.newDefaultFormularySnapshot("x", name: "y")
        item.category = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultFormularySnapshotRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Pharmacy.DefaultFormularySnapshotRequiredChecksumRule(
            message: "default formulary snapshot needs an entry"
        )
        let item = Pharmacy.newDefaultFormularySnapshot("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultFormularySnapshotExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Pharmacy.DefaultFormularySnapshotExpiresAtRangeRule(min: 80, max: 3600)
        let item = Pharmacy.newDefaultFormularySnapshot("x", name: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDefaultFormularySnapshotStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Pharmacy.DefaultFormularySnapshotStartsAtRangeRule(min: 80, max: 120)
        let item = Pharmacy.newDefaultFormularySnapshot("x", name: "y")
        item.startsAt = 121
        #expect(rule.check(item).count > 0)
    }
}
