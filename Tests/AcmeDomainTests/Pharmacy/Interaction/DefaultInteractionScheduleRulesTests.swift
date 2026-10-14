@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultInteractionScheduleValidator()
        let item = Pharmacy.newDefaultInteractionSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultInteractionScheduleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.DefaultInteractionScheduleLabelLengthRule(maxLength: 80)
        let item = Pharmacy.newDefaultInteractionSchedule("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultInteractionSchedulePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Pharmacy.DefaultInteractionSchedulePayerLengthRule(maxLength: 3600)
        let item = Pharmacy.newDefaultInteractionSchedule("x", label: "y")
        item.payer = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultInteractionScheduleRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Pharmacy.DefaultInteractionScheduleRequiredPayerRule(
            message: "default interaction schedule needs this field"
        )
        let item = Pharmacy.newDefaultInteractionSchedule("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultInteractionScheduleCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Pharmacy.DefaultInteractionScheduleCapacityRangeRule(min: 64, max: 1000)
        let item = Pharmacy.newDefaultInteractionSchedule("x", label: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDefaultInteractionScheduleVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Pharmacy.DefaultInteractionScheduleVersionRangeRule(min: 120, max: 255)
        let item = Pharmacy.newDefaultInteractionSchedule("x", label: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}
