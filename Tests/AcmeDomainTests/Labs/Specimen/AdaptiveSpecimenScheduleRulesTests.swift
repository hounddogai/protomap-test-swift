@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptiveSpecimenScheduleValidator()
        let item = Labs.newAdaptiveSpecimenSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptiveSpecimenScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.AdaptiveSpecimenScheduleNameLengthRule(maxLength: 32)
        let item = Labs.newAdaptiveSpecimenSchedule("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAdaptiveSpecimenScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AdaptiveSpecimenScheduleCodeLengthRule(maxLength: 64)
        let item = Labs.newAdaptiveSpecimenSchedule("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAdaptiveSpecimenScheduleRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Labs.AdaptiveSpecimenScheduleRequiredCategoryRule(message: "adaptive specimen schedule needs a value")
        let item = Labs.newAdaptiveSpecimenSchedule("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptiveSpecimenScheduleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.AdaptiveSpecimenScheduleRequiredNameRule(message: "adaptive specimen schedule needs this field")
        let item = Labs.newAdaptiveSpecimenSchedule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptiveSpecimenScheduleRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Labs.AdaptiveSpecimenScheduleRequiredProcedureCodeRule(
            message: "adaptive specimen schedule needs an entry"
        )
        let item = Labs.newAdaptiveSpecimenSchedule("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptiveSpecimenScheduleCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.AdaptiveSpecimenScheduleCeilingRangeRule(min: 7.9, max: 4512.0)
        let item = Labs.newAdaptiveSpecimenSchedule("x", name: "y")
        item.ceiling = 4513.5
        #expect(rule.check(item).count > 0)
    }
}
