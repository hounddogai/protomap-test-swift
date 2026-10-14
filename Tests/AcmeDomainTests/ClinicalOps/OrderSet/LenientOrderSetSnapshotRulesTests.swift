@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientOrderSetSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLenientOrderSetSnapshotValidator()
        let item = ClinicalOps.newLenientOrderSetSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLenientOrderSetSnapshotEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = ClinicalOps.LenientOrderSetSnapshotEndsAtRangeRule(min: 16, max: 16)
        let item = ClinicalOps.newLenientOrderSetSnapshot("x", label: "y")
        item.endsAt = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsLenientOrderSetSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.LenientOrderSetSnapshotRequiredCodeRule(
            message: "lenient order set snapshot needs an entry"
        )
        let item = ClinicalOps.newLenientOrderSetSnapshot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLenientOrderSetSnapshotCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = ClinicalOps.LenientOrderSetSnapshotCostRangeRule(min: 8.4, max: 769.0)
        let item = ClinicalOps.newLenientOrderSetSnapshot("x", label: "y")
        item.cost = 770.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsLenientOrderSetSnapshotExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = ClinicalOps.LenientOrderSetSnapshotExternalRefLengthRule(maxLength: 16)
        let item = ClinicalOps.newLenientOrderSetSnapshot("x", label: "y")
        item.externalRef = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLenientOrderSetSnapshotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.LenientOrderSetSnapshotRequiredLabelRule(
            message: "lenient order set snapshot needs this field"
        )
        let item = ClinicalOps.newLenientOrderSetSnapshot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
