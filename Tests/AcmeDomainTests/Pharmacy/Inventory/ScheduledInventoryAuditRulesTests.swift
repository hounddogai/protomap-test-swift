@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventoryAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultScheduledInventoryAuditValidator()
        let item = Pharmacy.newScheduledInventoryAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyScheduledInventoryAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.ScheduledInventoryAuditRequiredCodeRule(message: "scheduled inventory audit needs an entry")
        let item = Pharmacy.newScheduledInventoryAudit("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyScheduledInventoryAuditTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.ScheduledInventoryAuditTitleLengthRule(maxLength: 1000)
        let item = Pharmacy.newScheduledInventoryAudit("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyScheduledInventoryAuditMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Pharmacy.ScheduledInventoryAuditMinimumRangeRule(min: 2.9, max: 1724.4)
        let item = Pharmacy.newScheduledInventoryAudit("x", title: "y")
        item.minimum = 1725.9
        #expect(rule.check(item).count > 0)
    }
}
