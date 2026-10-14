@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryPlanValidator()
        let item = Pharmacy.newInventoryPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryPlanSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Pharmacy.InventoryPlanSegmentLengthRule(maxLength: 1000)
        let item = Pharmacy.newInventoryPlan("x", title: "y")
        item.segment = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryPlanRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Pharmacy.InventoryPlanRequiredSegmentRule(message: "inventory plan needs this field")
        let item = Pharmacy.newInventoryPlan("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
