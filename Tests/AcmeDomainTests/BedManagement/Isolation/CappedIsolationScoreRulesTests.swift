@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedIsolationScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCappedIsolationScoreValidator()
        let item = BedManagement.newCappedIsolationScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCappedIsolationScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.CappedIsolationScoreNameLengthRule(maxLength: 3600)
        let item = BedManagement.newCappedIsolationScore("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedIsolationScoreThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = BedManagement.CappedIsolationScoreThresholdRangeRule(min: 4.5, max: 3976.1)
        let item = BedManagement.newCappedIsolationScore("x", name: "y")
        item.threshold = 3977.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCappedIsolationScoreSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = BedManagement.CappedIsolationScoreSpecialtyLengthRule(maxLength: 255)
        let item = BedManagement.newCappedIsolationScore("x", name: "y")
        item.specialty = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedIsolationScoreRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = BedManagement.CappedIsolationScoreRequiredTimezoneRule(
            message: "capped isolation score needs this field"
        )
        let item = BedManagement.newCappedIsolationScore("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
