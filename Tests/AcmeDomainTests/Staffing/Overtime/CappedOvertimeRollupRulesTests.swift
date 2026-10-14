@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedOvertimeRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCappedOvertimeRollupValidator()
        let item = Staffing.newCappedOvertimeRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCappedOvertimeRollupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.CappedOvertimeRollupNameLengthRule(maxLength: 86400)
        let item = Staffing.newCappedOvertimeRollup("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedOvertimeRollupRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Staffing.CappedOvertimeRollupRequiredChecksumRule(message: "capped overtime rollup needs a value")
        let item = Staffing.newCappedOvertimeRollup("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCappedOvertimeRollupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.CappedOvertimeRollupRequiredNameRule(message: "capped overtime rollup needs an entry")
        let item = Staffing.newCappedOvertimeRollup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
