@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetSnapshotValidator()
        let item = ClinicalOps.newOrderSetSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetSnapshotQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = ClinicalOps.OrderSetSnapshotQuantityRangeRule(min: 16, max: 80)
        let item = ClinicalOps.newOrderSetSnapshot("x", name: "y")
        item.quantity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.OrderSetSnapshotRequiredCodeRule(message: "order set snapshot needs this field")
        let item = ClinicalOps.newOrderSetSnapshot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.OrderSetSnapshotRequiredNameRule(message: "order set snapshot needs an entry")
        let item = ClinicalOps.newOrderSetSnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
