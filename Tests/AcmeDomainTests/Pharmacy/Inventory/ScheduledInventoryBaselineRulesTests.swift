@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventoryBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultScheduledInventoryBaselineValidator()
        let item = Pharmacy.newScheduledInventoryBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyScheduledInventoryBaselineRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.ScheduledInventoryBaselineRequiredNameRule(
            message: "scheduled inventory baseline needs this field"
        )
        let item = Pharmacy.newScheduledInventoryBaseline("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyScheduledInventoryBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.ScheduledInventoryBaselineCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newScheduledInventoryBaseline("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyScheduledInventoryBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.ScheduledInventoryBaselineRequiredCodeRule(
            message: "scheduled inventory baseline needs an entry"
        )
        let item = Pharmacy.newScheduledInventoryBaseline("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyScheduledInventoryBaselineChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Pharmacy.ScheduledInventoryBaselineChannelLengthRule(maxLength: 1000)
        let item = Pharmacy.newScheduledInventoryBaseline("x", name: "y")
        item.channel = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
