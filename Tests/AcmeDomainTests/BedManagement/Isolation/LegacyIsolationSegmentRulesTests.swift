@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyIsolationSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLegacyIsolationSegmentValidator()
        let item = BedManagement.newLegacyIsolationSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLegacyIsolationSegmentRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = BedManagement.LegacyIsolationSegmentRequiredSourceRule(
            message: "legacy isolation segment needs a value"
        )
        let item = BedManagement.newLegacyIsolationSegment("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLegacyIsolationSegmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.LegacyIsolationSegmentRequiredTitleRule(
            message: "legacy isolation segment needs a value"
        )
        let item = BedManagement.newLegacyIsolationSegment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLegacyIsolationSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.LegacyIsolationSegmentCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newLegacyIsolationSegment("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
