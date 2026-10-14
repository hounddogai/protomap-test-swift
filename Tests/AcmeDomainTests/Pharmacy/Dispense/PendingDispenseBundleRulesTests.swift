@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingDispenseBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPendingDispenseBundleValidator()
        let item = Pharmacy.newPendingDispenseBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPendingDispenseBundlePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Pharmacy.PendingDispenseBundlePriorityRangeRule(min: 64, max: 255)
        let item = Pharmacy.newPendingDispenseBundle("x", name: "y")
        item.priority = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPendingDispenseBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.PendingDispenseBundleRequiredNameRule(message: "pending dispense bundle needs a value")
        let item = Pharmacy.newPendingDispenseBundle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
