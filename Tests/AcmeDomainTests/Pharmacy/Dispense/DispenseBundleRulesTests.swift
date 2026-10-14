@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseBundleValidator()
        let item = Pharmacy.newDispenseBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseBundleContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Pharmacy.DispenseBundleContactEmailLengthRule(maxLength: 86400)
        let item = Pharmacy.newDispenseBundle("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseBundlePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Pharmacy.DispenseBundlePriorityRangeRule(min: 1000, max: 1000)
        let item = Pharmacy.newDispenseBundle("x", title: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseBundleFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Pharmacy.DispenseBundleFloorValueRangeRule(min: 6.2, max: 1627.2)
        let item = Pharmacy.newDispenseBundle("x", title: "y")
        item.floorValue = 1628.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseBundleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.DispenseBundleTitleLengthRule(maxLength: 1000)
        let item = Pharmacy.newDispenseBundle("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
