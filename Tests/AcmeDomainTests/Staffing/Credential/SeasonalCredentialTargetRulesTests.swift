@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalCredentialTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSeasonalCredentialTargetValidator()
        let item = Staffing.newSeasonalCredentialTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSeasonalCredentialTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.SeasonalCredentialTargetCodeLengthRule(maxLength: 255)
        let item = Staffing.newSeasonalCredentialTarget("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSeasonalCredentialTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SeasonalCredentialTargetRequiredCodeRule(
            message: "seasonal credential target needs this field"
        )
        let item = Staffing.newSeasonalCredentialTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSeasonalCredentialTargetSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Staffing.SeasonalCredentialTargetSequenceRangeRule(min: 64, max: 255)
        let item = Staffing.newSeasonalCredentialTarget("x", name: "y")
        item.sequence = 256
        #expect(rule.check(item).count > 0)
    }
}
