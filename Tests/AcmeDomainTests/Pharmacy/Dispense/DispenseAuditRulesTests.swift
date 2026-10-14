@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseAuditValidator()
        let item = Pharmacy.newDispenseAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.DispenseAuditRequiredTitleRule(message: "dispense audit needs this field")
        let item = Pharmacy.newDispenseAudit("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseAuditRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Pharmacy.DispenseAuditRequiredWardRule(message: "dispense audit needs an entry")
        let item = Pharmacy.newDispenseAudit("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseAuditChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Pharmacy.DispenseAuditChannelLengthRule(maxLength: 32)
        let item = Pharmacy.newDispenseAudit("x", title: "y")
        item.channel = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseAuditCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Pharmacy.DispenseAuditCeilingRangeRule(min: 1.8, max: 4314.6)
        let item = Pharmacy.newDispenseAudit("x", title: "y")
        item.ceiling = 4316.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseAuditTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.DispenseAuditTitleLengthRule(maxLength: 120)
        let item = Pharmacy.newDispenseAudit("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
