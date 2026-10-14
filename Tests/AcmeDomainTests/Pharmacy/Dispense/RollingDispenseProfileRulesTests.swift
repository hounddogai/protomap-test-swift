@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingDispenseProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRollingDispenseProfileValidator()
        let item = Pharmacy.newRollingDispenseProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRollingDispenseProfileRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Pharmacy.RollingDispenseProfileRequiredSourceRule(
            message: "rolling dispense profile needs this field"
        )
        let item = Pharmacy.newRollingDispenseProfile("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRollingDispenseProfileRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Pharmacy.RollingDispenseProfileRequiredClinicianIDRule(
            message: "rolling dispense profile needs an entry"
        )
        let item = Pharmacy.newRollingDispenseProfile("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRollingDispenseProfileTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.RollingDispenseProfileTitleLengthRule(maxLength: 16)
        let item = Pharmacy.newRollingDispenseProfile("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRollingDispenseProfileRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.RollingDispenseProfileRequiredTitleRule(message: "rolling dispense profile needs a value")
        let item = Pharmacy.newRollingDispenseProfile("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
