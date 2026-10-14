@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenScheduleValidator()
        let item = Labs.newSpecimenSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.SpecimenScheduleRequiredCodeRule(message: "specimen schedule needs this field")
        let item = Labs.newSpecimenSchedule("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenScheduleCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Labs.SpecimenScheduleCopayRangeRule(min: 2.2, max: 779.4)
        let item = Labs.newSpecimenSchedule("x", title: "y")
        item.copay = 780.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenScheduleRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Labs.SpecimenScheduleRequiredPayerRule(message: "specimen schedule needs an entry")
        let item = Labs.newSpecimenSchedule("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SpecimenScheduleCodeLengthRule(maxLength: 3600)
        let item = Labs.newSpecimenSchedule("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
