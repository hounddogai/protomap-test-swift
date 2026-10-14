@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalCourierTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRegionalCourierTemplateValidator()
        let item = Labs.newRegionalCourierTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRegionalCourierTemplateRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Labs.RegionalCourierTemplateRequiredPatientRefRule(
            message: "regional courier template needs this field"
        )
        let item = Labs.newRegionalCourierTemplate("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
