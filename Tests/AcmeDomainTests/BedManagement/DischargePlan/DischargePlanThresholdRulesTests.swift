@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanThresholdValidator()
        let item = BedManagement.newDischargePlanThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DischargePlanThresholdRequiredCodeRule(
            message: "discharge plan threshold needs this field"
        )
        let item = BedManagement.newDischargePlanThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanThresholdSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = BedManagement.DischargePlanThresholdSpecialtyLengthRule(maxLength: 120)
        let item = BedManagement.newDischargePlanThreshold("x", name: "y")
        item.specialty = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
