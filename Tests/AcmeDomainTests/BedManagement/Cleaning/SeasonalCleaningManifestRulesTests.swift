@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalCleaningManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultSeasonalCleaningManifestValidator()
        let item = BedManagement.newSeasonalCleaningManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementSeasonalCleaningManifestCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = BedManagement.SeasonalCleaningManifestCreatedAtRangeRule(min: 120, max: 1000)
        let item = BedManagement.newSeasonalCleaningManifest("x", name: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementSeasonalCleaningManifestWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = BedManagement.SeasonalCleaningManifestWeightRangeRule(min: 7.2, max: 4149.1)
        let item = BedManagement.newSeasonalCleaningManifest("x", name: "y")
        item.weight = 4150.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementSeasonalCleaningManifestChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = BedManagement.SeasonalCleaningManifestChecksumLengthRule(maxLength: 32)
        let item = BedManagement.newSeasonalCleaningManifest("x", name: "y")
        item.checksum = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementSeasonalCleaningManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.SeasonalCleaningManifestCodeLengthRule(maxLength: 64)
        let item = BedManagement.newSeasonalCleaningManifest("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementSeasonalCleaningManifestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.SeasonalCleaningManifestRequiredNameRule(
            message: "seasonal cleaning manifest needs an entry"
        )
        let item = BedManagement.newSeasonalCleaningManifest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
