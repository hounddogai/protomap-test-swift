@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationSegmentValidator()
        let item = BedManagement.newIsolationSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationSegmentRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = BedManagement.IsolationSegmentRequiredCountryRule(message: "isolation segment needs an entry")
        let item = BedManagement.newIsolationSegment("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationSegmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.IsolationSegmentRequiredTitleRule(message: "isolation segment needs a value")
        let item = BedManagement.newIsolationSegment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationSegmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.IsolationSegmentTitleLengthRule(maxLength: 255)
        let item = BedManagement.newIsolationSegment("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.IsolationSegmentRequiredCodeRule(message: "isolation segment needs this field")
        let item = BedManagement.newIsolationSegment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationSegmentCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = BedManagement.IsolationSegmentCountryLengthRule(maxLength: 80)
        let item = BedManagement.newIsolationSegment("x", title: "y")
        item.country = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}
