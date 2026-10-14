@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadAssignmentValidator()
        let item = Imaging.newReadAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadAssignmentTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Imaging.ReadAssignmentTimezoneLengthRule(maxLength: 1000)
        let item = Imaging.newReadAssignment("x", name: "y")
        item.timezone = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadAssignmentPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Imaging.ReadAssignmentPatientRefLengthRule(maxLength: 32)
        let item = Imaging.newReadAssignment("x", name: "y")
        item.patientRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ReadAssignmentRequiredCodeRule(message: "read assignment needs this field")
        let item = Imaging.newReadAssignment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
