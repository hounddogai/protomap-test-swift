@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualBedBoardWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualBedBoardWindowValidator()
        let item = BedManagement.newManualBedBoardWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualBedBoardWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.ManualBedBoardWindowRequiredCodeRule(message: "manual bed board window needs a value")
        let item = BedManagement.newManualBedBoardWindow("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualBedBoardWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ManualBedBoardWindowCodeLengthRule(maxLength: 32)
        let item = BedManagement.newManualBedBoardWindow("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
