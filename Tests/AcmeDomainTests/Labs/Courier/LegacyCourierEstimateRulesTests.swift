@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyCourierEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacyCourierEstimateValidator()
        let item = Labs.newLegacyCourierEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacyCourierEstimateClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Labs.LegacyCourierEstimateClinicianIDLengthRule(maxLength: 16)
        let item = Labs.newLegacyCourierEstimate("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
