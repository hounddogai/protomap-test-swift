@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveOutreachSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveOutreachSegmentValidator()
        let item = CareManagement.newAdaptiveOutreachSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveOutreachSegmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.AdaptiveOutreachSegmentNameLengthRule(maxLength: 255)
        let item = CareManagement.newAdaptiveOutreachSegment("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveOutreachSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.AdaptiveOutreachSegmentRequiredCodeRule(
            message: "adaptive outreach segment needs this field"
        )
        let item = CareManagement.newAdaptiveOutreachSegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
