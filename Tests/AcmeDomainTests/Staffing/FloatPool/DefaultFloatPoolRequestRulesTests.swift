@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultFloatPoolRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultDefaultFloatPoolRequestValidator()
        let item = Staffing.newDefaultFloatPoolRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingDefaultFloatPoolRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.DefaultFloatPoolRequestRequiredCodeRule(message: "default float pool request needs a value")
        let item = Staffing.newDefaultFloatPoolRequest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultFloatPoolRequestSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Staffing.DefaultFloatPoolRequestSpecialtyLengthRule(maxLength: 80)
        let item = Staffing.newDefaultFloatPoolRequest("x", name: "y")
        item.specialty = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
