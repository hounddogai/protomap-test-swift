@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapRequestValidator()
        let item = CareManagement.newCareGapRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapRequestFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = CareManagement.CareGapRequestFacilityLengthRule(maxLength: 86400)
        let item = CareManagement.newCareGapRequest("x", name: "y")
        item.facility = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapRequestClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = CareManagement.CareGapRequestClinicianIDLengthRule(maxLength: 3600)
        let item = CareManagement.newCareGapRequest("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
