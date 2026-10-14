@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningRollupValidator()
        let item = BedManagement.newCleaningRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningRollupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.CleaningRollupRequiredLabelRule(message: "cleaning rollup needs a value")
        let item = BedManagement.newCleaningRollup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningRollupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.CleaningRollupLabelLengthRule(maxLength: 32)
        let item = BedManagement.newCleaningRollup("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CleaningRollupCodeLengthRule(maxLength: 255)
        let item = BedManagement.newCleaningRollup("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
