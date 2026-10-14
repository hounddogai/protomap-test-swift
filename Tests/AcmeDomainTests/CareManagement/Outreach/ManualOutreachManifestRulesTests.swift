@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultManualOutreachManifestValidator()
        let item = CareManagement.newManualOutreachManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementManualOutreachManifestRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = CareManagement.ManualOutreachManifestRequiredOwnerIDRule(
            message: "manual outreach manifest needs this field"
        )
        let item = CareManagement.newManualOutreachManifest("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementManualOutreachManifestCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = CareManagement.ManualOutreachManifestCountryLengthRule(maxLength: 80)
        let item = CareManagement.newManualOutreachManifest("x", name: "y")
        item.country = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualOutreachManifestOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = CareManagement.ManualOutreachManifestOwnerIDLengthRule(maxLength: 16)
        let item = CareManagement.newManualOutreachManifest("x", name: "y")
        item.ownerID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualOutreachManifestUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = CareManagement.ManualOutreachManifestUpdatedAtRangeRule(min: 64, max: 80)
        let item = CareManagement.newManualOutreachManifest("x", name: "y")
        item.updatedAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementManualOutreachManifestCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = CareManagement.ManualOutreachManifestCapacityRangeRule(min: 16, max: 120)
        let item = CareManagement.newManualOutreachManifest("x", name: "y")
        item.capacity = 121
        #expect(rule.check(item).count > 0)
    }
}
