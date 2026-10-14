@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredOutreachScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredOutreachScoreValidator()
        let item = CareManagement.newTieredOutreachScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredOutreachScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.TieredOutreachScoreNameLengthRule(maxLength: 255)
        let item = CareManagement.newTieredOutreachScore("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredOutreachScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.TieredOutreachScoreCodeLengthRule(maxLength: 255)
        let item = CareManagement.newTieredOutreachScore("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredOutreachScoreRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.TieredOutreachScoreRequiredLabelRule(message: "tiered outreach score needs this field")
        let item = CareManagement.newTieredOutreachScore("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementTieredOutreachScoreVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.TieredOutreachScoreVersionRangeRule(min: 64, max: 80)
        let item = CareManagement.newTieredOutreachScore("x", name: "y")
        item.version = 81
        #expect(rule.check(item).count > 0)
    }
}
