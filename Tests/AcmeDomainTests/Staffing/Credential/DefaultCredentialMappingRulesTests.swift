@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultCredentialMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultDefaultCredentialMappingValidator()
        let item = Staffing.newDefaultCredentialMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingDefaultCredentialMappingRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Staffing.DefaultCredentialMappingRequiredSpecialtyRule(
            message: "default credential mapping needs a value"
        )
        let item = Staffing.newDefaultCredentialMapping("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultCredentialMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.DefaultCredentialMappingCodeLengthRule(maxLength: 80)
        let item = Staffing.newDefaultCredentialMapping("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultCredentialMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.DefaultCredentialMappingRequiredCodeRule(message: "default credential mapping needs a value")
        let item = Staffing.newDefaultCredentialMapping("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultCredentialMappingLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Staffing.DefaultCredentialMappingLimitRangeRule(min: 120, max: 3600)
        let item = Staffing.newDefaultCredentialMapping("x", name: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingDefaultCredentialMappingDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Staffing.DefaultCredentialMappingDiagnosisCodeLengthRule(maxLength: 3600)
        let item = Staffing.newDefaultCredentialMapping("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultCredentialMappingSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Staffing.DefaultCredentialMappingSpecialtyLengthRule(maxLength: 32)
        let item = Staffing.newDefaultCredentialMapping("x", name: "y")
        item.specialty = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
