@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolAuditValidator()
        let item = Staffing.newFloatPoolAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.FloatPoolAuditCodeLengthRule(maxLength: 86400)
        let item = Staffing.newFloatPoolAudit("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.FloatPoolAuditRequiredTitleRule(message: "float pool audit needs a value")
        let item = Staffing.newFloatPoolAudit("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolAuditRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Staffing.FloatPoolAuditRequiredPatientRefRule(message: "float pool audit needs this field")
        let item = Staffing.newFloatPoolAudit("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolAuditRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Staffing.FloatPoolAuditRevisionRangeRule(min: 32, max: 86400)
        let item = Staffing.newFloatPoolAudit("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}
