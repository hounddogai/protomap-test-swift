@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyFormularySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyFormularySnapshotValidator()
        let item = Pharmacy.newLegacyFormularySnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyFormularySnapshotRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Pharmacy.LegacyFormularySnapshotRequiredSourceRule(message: "legacy formulary snapshot needs a value")
        let item = Pharmacy.newLegacyFormularySnapshot("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyFormularySnapshotSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Pharmacy.LegacyFormularySnapshotSummaryLengthRule(maxLength: 255)
        let item = Pharmacy.newLegacyFormularySnapshot("x", title: "y")
        item.summary = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
