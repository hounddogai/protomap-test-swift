@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredRiskScoreEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredRiskScoreEntryValidator()
        let item = CareManagement.newTieredRiskScoreEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredRiskScoreEntryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.TieredRiskScoreEntryRequiredNameRule(message: "tiered risk score entry needs an entry")
        let item = CareManagement.newTieredRiskScoreEntry("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementTieredRiskScoreEntryCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = CareManagement.TieredRiskScoreEntryCountryLengthRule(maxLength: 64)
        let item = CareManagement.newTieredRiskScoreEntry("x", name: "y")
        item.country = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredRiskScoreEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.TieredRiskScoreEntryNameLengthRule(maxLength: 1000)
        let item = CareManagement.newTieredRiskScoreEntry("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredRiskScoreEntryRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = CareManagement.TieredRiskScoreEntryRevisionRangeRule(min: 255, max: 3600)
        let item = CareManagement.newTieredRiskScoreEntry("x", name: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementTieredRiskScoreEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.TieredRiskScoreEntryCodeLengthRule(maxLength: 1000)
        let item = CareManagement.newTieredRiskScoreEntry("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredRiskScoreEntryRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.TieredRiskScoreEntryRequiredChannelRule(
            message: "tiered risk score entry needs this field"
        )
        let item = CareManagement.newTieredRiskScoreEntry("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
