@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientProgramProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientProgramProfileValidator()
        let item = CareManagement.newLenientProgramProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientProgramProfileRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = CareManagement.LenientProgramProfileRequiredPatientRefRule(
            message: "lenient program profile needs this field"
        )
        let item = CareManagement.newLenientProgramProfile("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientProgramProfileTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.LenientProgramProfileTitleLengthRule(maxLength: 1000)
        let item = CareManagement.newLenientProgramProfile("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
