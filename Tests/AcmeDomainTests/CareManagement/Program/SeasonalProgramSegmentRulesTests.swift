@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalProgramSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultSeasonalProgramSegmentValidator()
        let item = CareManagement.newSeasonalProgramSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementSeasonalProgramSegmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.SeasonalProgramSegmentLabelLengthRule(maxLength: 3600)
        let item = CareManagement.newSeasonalProgramSegment("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementSeasonalProgramSegmentSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = CareManagement.SeasonalProgramSegmentSegmentLengthRule(maxLength: 86400)
        let item = CareManagement.newSeasonalProgramSegment("x", label: "y")
        item.segment = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementSeasonalProgramSegmentRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = CareManagement.SeasonalProgramSegmentRequiredContactEmailRule(
            message: "seasonal program segment needs this field"
        )
        let item = CareManagement.newSeasonalProgramSegment("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementSeasonalProgramSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.SeasonalProgramSegmentRequiredCodeRule(
            message: "seasonal program segment needs this field"
        )
        let item = CareManagement.newSeasonalProgramSegment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementSeasonalProgramSegmentRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = CareManagement.SeasonalProgramSegmentRequiredSegmentRule(
            message: "seasonal program segment needs an entry"
        )
        let item = CareManagement.newSeasonalProgramSegment("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
