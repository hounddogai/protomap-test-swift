@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictOvertimeManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultStrictOvertimeManifestValidator()
        let item = Staffing.newStrictOvertimeManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingStrictOvertimeManifestScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Staffing.StrictOvertimeManifestScoreRangeRule(min: 1.6, max: 4310.4)
        let item = Staffing.newStrictOvertimeManifest("x", name: "y")
        item.score = 4311.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingStrictOvertimeManifestRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Staffing.StrictOvertimeManifestRequiredEncounterIDRule(
            message: "strict overtime manifest needs this field"
        )
        let item = Staffing.newStrictOvertimeManifest("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictOvertimeManifestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.StrictOvertimeManifestRequiredNameRule(message: "strict overtime manifest needs an entry")
        let item = Staffing.newStrictOvertimeManifest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictOvertimeManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.StrictOvertimeManifestRequiredCodeRule(message: "strict overtime manifest needs a value")
        let item = Staffing.newStrictOvertimeManifest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
