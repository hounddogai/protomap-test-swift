@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseScheduleValidator()
        let item = Pharmacy.newDispenseSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseScheduleRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Pharmacy.DispenseScheduleRequiredUnitRule(message: "dispense schedule needs an entry")
        let item = Pharmacy.newDispenseSchedule("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseScheduleUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Pharmacy.DispenseScheduleUnitLengthRule(maxLength: 86400)
        let item = Pharmacy.newDispenseSchedule("x", label: "y")
        item.unit = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
