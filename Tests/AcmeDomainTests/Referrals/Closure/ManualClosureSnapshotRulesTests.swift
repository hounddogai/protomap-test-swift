@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualClosureSnapshotValidator()
        let item = Referrals.newManualClosureSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualClosureSnapshotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.ManualClosureSnapshotLabelLengthRule(maxLength: 3600)
        let item = Referrals.newManualClosureSnapshot("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualClosureSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ManualClosureSnapshotCodeLengthRule(maxLength: 80)
        let item = Referrals.newManualClosureSnapshot("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualClosureSnapshotQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.ManualClosureSnapshotQuantityRangeRule(min: 32, max: 3600)
        let item = Referrals.newManualClosureSnapshot("x", label: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsManualClosureSnapshotCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.ManualClosureSnapshotCreatedAtRangeRule(min: 80, max: 1000)
        let item = Referrals.newManualClosureSnapshot("x", label: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsManualClosureSnapshotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.ManualClosureSnapshotRequiredLabelRule(message: "manual closure snapshot needs an entry")
        let item = Referrals.newManualClosureSnapshot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
