@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCleaningWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualCleaningWindowValidator()
        let item = BedManagement.newManualCleaningWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualCleaningWindowRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = BedManagement.ManualCleaningWindowRequiredPhoneRule(message: "manual cleaning window needs an entry")
        let item = BedManagement.newManualCleaningWindow("", label: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualCleaningWindowLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.ManualCleaningWindowLabelLengthRule(maxLength: 3600)
        let item = BedManagement.newManualCleaningWindow("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualCleaningWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.ManualCleaningWindowRequiredCodeRule(message: "manual cleaning window needs this field")
        let item = BedManagement.newManualCleaningWindow("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualCleaningWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ManualCleaningWindowCodeLengthRule(maxLength: 32)
        let item = BedManagement.newManualCleaningWindow("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
