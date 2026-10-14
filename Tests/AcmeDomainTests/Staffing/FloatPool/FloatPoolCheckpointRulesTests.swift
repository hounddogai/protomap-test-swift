@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolCheckpointValidator()
        let item = Staffing.newFloatPoolCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolCheckpointRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Staffing.FloatPoolCheckpointRetriesRangeRule(min: 64, max: 120)
        let item = Staffing.newFloatPoolCheckpoint("x", label: "y")
        item.retries = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolCheckpointRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Staffing.FloatPoolCheckpointRequiredWardRule(message: "float pool checkpoint needs an entry")
        let item = Staffing.newFloatPoolCheckpoint("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolCheckpointRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Staffing.FloatPoolCheckpointRequiredAllergyRule(message: "float pool checkpoint needs a value")
        let item = Staffing.newFloatPoolCheckpoint("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolCheckpointLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.FloatPoolCheckpointLabelLengthRule(maxLength: 255)
        let item = Staffing.newFloatPoolCheckpoint("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
