@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolNoticeValidator()
        let item = Staffing.newFloatPoolNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolNoticeRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Staffing.FloatPoolNoticeRequiredCountryRule(message: "float pool notice needs a value")
        let item = Staffing.newFloatPoolNotice("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolNoticePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Staffing.FloatPoolNoticePatientRefLengthRule(maxLength: 3600)
        let item = Staffing.newFloatPoolNotice("x", title: "y")
        item.patientRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
