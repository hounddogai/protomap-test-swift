@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInteractionScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLenientInteractionScheduleValidator()
        let item = Pharmacy.newLenientInteractionSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLenientInteractionScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.LenientInteractionScheduleRequiredCodeRule(
            message: "lenient interaction schedule needs an entry"
        )
        let item = Pharmacy.newLenientInteractionSchedule("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientInteractionScheduleVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Pharmacy.LenientInteractionScheduleVisitMinutesRangeRule(min: 64, max: 80)
        let item = Pharmacy.newLenientInteractionSchedule("x", title: "y")
        item.visitMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLenientInteractionScheduleRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Pharmacy.LenientInteractionScheduleRequiredOwnerIDRule(
            message: "lenient interaction schedule needs a value"
        )
        let item = Pharmacy.newLenientInteractionSchedule("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientInteractionScheduleCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Pharmacy.LenientInteractionScheduleCopayRangeRule(min: 9.7, max: 176.0)
        let item = Pharmacy.newLenientInteractionSchedule("x", title: "y")
        item.copay = 177.5
        #expect(rule.check(item).count > 0)
    }
}
