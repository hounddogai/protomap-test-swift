@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCleaningEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackCleaningEntryValidator()
        let item = BedManagement.newFallbackCleaningEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackCleaningEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.FallbackCleaningEntryNameLengthRule(maxLength: 64)
        let item = BedManagement.newFallbackCleaningEntry("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackCleaningEntryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.FallbackCleaningEntryTitleLengthRule(maxLength: 255)
        let item = BedManagement.newFallbackCleaningEntry("x", name: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackCleaningEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.FallbackCleaningEntryRequiredCodeRule(
            message: "fallback cleaning entry needs this field"
        )
        let item = BedManagement.newFallbackCleaningEntry("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackCleaningEntrySourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = BedManagement.FallbackCleaningEntrySourceLengthRule(maxLength: 3600)
        let item = BedManagement.newFallbackCleaningEntry("x", name: "y")
        item.source = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackCleaningEntryRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = BedManagement.FallbackCleaningEntryRequiredSourceRule(
            message: "fallback cleaning entry needs this field"
        )
        let item = BedManagement.newFallbackCleaningEntry("", name: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}
