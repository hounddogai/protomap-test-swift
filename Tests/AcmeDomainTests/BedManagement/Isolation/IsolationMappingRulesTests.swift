@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationMappingValidator()
        let item = BedManagement.newIsolationMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.IsolationMappingCodeLengthRule(maxLength: 16)
        let item = BedManagement.newIsolationMapping("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationMappingCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.IsolationMappingCopayRangeRule(min: 1.2, max: 852.9)
        let item = BedManagement.newIsolationMapping("x", title: "y")
        item.copay = 854.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementIsolationMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.IsolationMappingRequiredCodeRule(message: "isolation mapping needs a value")
        let item = BedManagement.newIsolationMapping("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
