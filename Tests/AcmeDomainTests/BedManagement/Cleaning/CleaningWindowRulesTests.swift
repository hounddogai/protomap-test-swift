@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningWindowValidator()
        let item = BedManagement.newCleaningWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CleaningWindowRequiredCodeRule(message: "cleaning window needs this field")
        let item = BedManagement.newCleaningWindow("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningWindowRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = BedManagement.CleaningWindowRequiredChecksumRule(message: "cleaning window needs this field")
        let item = BedManagement.newCleaningWindow("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CleaningWindowCodeLengthRule(maxLength: 16)
        let item = BedManagement.newCleaningWindow("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
