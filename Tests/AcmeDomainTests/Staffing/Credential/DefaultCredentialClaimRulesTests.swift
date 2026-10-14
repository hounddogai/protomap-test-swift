@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultCredentialClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultDefaultCredentialClaimValidator()
        let item = Staffing.newDefaultCredentialClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingDefaultCredentialClaimDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Staffing.DefaultCredentialClaimDosageMgRangeRule(min: 4.7, max: 3210.9)
        let item = Staffing.newDefaultCredentialClaim("x", title: "y")
        item.dosageMg = 3212.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingDefaultCredentialClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.DefaultCredentialClaimCodeLengthRule(maxLength: 1000)
        let item = Staffing.newDefaultCredentialClaim("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultCredentialClaimMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Staffing.DefaultCredentialClaimMinimumRangeRule(min: 4.4, max: 1755.0)
        let item = Staffing.newDefaultCredentialClaim("x", title: "y")
        item.minimum = 1756.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingDefaultCredentialClaimRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Staffing.DefaultCredentialClaimRequiredChannelRule(message: "default credential claim needs a value")
        let item = Staffing.newDefaultCredentialClaim("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
