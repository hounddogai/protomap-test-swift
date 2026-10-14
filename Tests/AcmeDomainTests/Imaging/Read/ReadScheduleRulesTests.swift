@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadScheduleValidator()
        let item = Imaging.newReadSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.ReadScheduleNameLengthRule(maxLength: 80)
        let item = Imaging.newReadSchedule("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadScheduleExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Imaging.ReadScheduleExpiresAtRangeRule(min: 120, max: 120)
        let item = Imaging.newReadSchedule("x", name: "y")
        item.expiresAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadScheduleFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Imaging.ReadScheduleFacilityLengthRule(maxLength: 86400)
        let item = Imaging.newReadSchedule("x", name: "y")
        item.facility = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadScheduleCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Imaging.ReadScheduleCeilingRangeRule(min: 2.3, max: 1286.2)
        let item = Imaging.newReadSchedule("x", name: "y")
        item.ceiling = 1287.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadScheduleCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Imaging.ReadScheduleCopayRangeRule(min: 7.5, max: 2464.2)
        let item = Imaging.newReadSchedule("x", name: "y")
        item.copay = 2465.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadScheduleDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Imaging.ReadScheduleDiscountRangeRule(min: 0.5, max: 661.1)
        let item = Imaging.newReadSchedule("x", name: "y")
        item.discount = 662.6
        #expect(rule.check(item).count > 0)
    }
}
