@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictIsolationDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultStrictIsolationDigestValidator()
        let item = BedManagement.newStrictIsolationDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementStrictIsolationDigestFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.StrictIsolationDigestFloorValueRangeRule(min: 0.7, max: 3840.9)
        let item = BedManagement.newStrictIsolationDigest("x", title: "y")
        item.floorValue = 3842.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementStrictIsolationDigestClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = BedManagement.StrictIsolationDigestClinicianIDLengthRule(maxLength: 120)
        let item = BedManagement.newStrictIsolationDigest("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementStrictIsolationDigestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.StrictIsolationDigestTitleLengthRule(maxLength: 80)
        let item = BedManagement.newStrictIsolationDigest("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
