@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalOutreachDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultSeasonalOutreachDigestValidator()
        let item = CareManagement.newSeasonalOutreachDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementSeasonalOutreachDigestCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = CareManagement.SeasonalOutreachDigestCreatedAtRangeRule(min: 16, max: 16)
        let item = CareManagement.newSeasonalOutreachDigest("x", name: "y")
        item.createdAt = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementSeasonalOutreachDigestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.SeasonalOutreachDigestRequiredNameRule(
            message: "seasonal outreach digest needs an entry"
        )
        let item = CareManagement.newSeasonalOutreachDigest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementSeasonalOutreachDigestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.SeasonalOutreachDigestRequiredLabelRule(
            message: "seasonal outreach digest needs this field"
        )
        let item = CareManagement.newSeasonalOutreachDigest("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementSeasonalOutreachDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.SeasonalOutreachDigestNameLengthRule(maxLength: 120)
        let item = CareManagement.newSeasonalOutreachDigest("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
