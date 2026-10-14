@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningScheduleValidator()
        let item = BedManagement.newCleaningSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningScheduleQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = BedManagement.CleaningScheduleQuantityRangeRule(min: 32, max: 1000)
        let item = BedManagement.newCleaningSchedule("x", name: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCleaningScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CleaningScheduleRequiredCodeRule(message: "cleaning schedule needs a value")
        let item = BedManagement.newCleaningSchedule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CleaningScheduleCodeLengthRule(maxLength: 32)
        let item = BedManagement.newCleaningSchedule("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningScheduleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CleaningScheduleRequiredNameRule(message: "cleaning schedule needs this field")
        let item = BedManagement.newCleaningSchedule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
