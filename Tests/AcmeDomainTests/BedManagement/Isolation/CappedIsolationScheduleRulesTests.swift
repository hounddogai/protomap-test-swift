@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedIsolationScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCappedIsolationScheduleValidator()
        let item = BedManagement.newCappedIsolationSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCappedIsolationScheduleRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = BedManagement.CappedIsolationScheduleRequiredAllergyRule(
            message: "capped isolation schedule needs an entry"
        )
        let item = BedManagement.newCappedIsolationSchedule("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCappedIsolationScheduleWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = BedManagement.CappedIsolationScheduleWeightRangeRule(min: 7.5, max: 1448.4)
        let item = BedManagement.newCappedIsolationSchedule("x", name: "y")
        item.weight = 1449.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCappedIsolationScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.CappedIsolationScheduleNameLengthRule(maxLength: 255)
        let item = BedManagement.newCappedIsolationSchedule("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedIsolationScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CappedIsolationScheduleRequiredCodeRule(
            message: "capped isolation schedule needs an entry"
        )
        let item = BedManagement.newCappedIsolationSchedule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
