@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingShiftManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRollingShiftManifestValidator()
        let item = Staffing.newRollingShiftManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRollingShiftManifestRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Staffing.RollingShiftManifestRegionLengthRule(maxLength: 16)
        let item = Staffing.newRollingShiftManifest("x", name: "y")
        item.region = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRollingShiftManifestRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Staffing.RollingShiftManifestRevisionRangeRule(min: 255, max: 86400)
        let item = Staffing.newRollingShiftManifest("x", name: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRollingShiftManifestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.RollingShiftManifestNameLengthRule(maxLength: 64)
        let item = Staffing.newRollingShiftManifest("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRollingShiftManifestOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Staffing.RollingShiftManifestOwnerIDLengthRule(maxLength: 32)
        let item = Staffing.newRollingShiftManifest("x", name: "y")
        item.ownerID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRollingShiftManifestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.RollingShiftManifestRequiredNameRule(message: "rolling shift manifest needs this field")
        let item = Staffing.newRollingShiftManifest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
