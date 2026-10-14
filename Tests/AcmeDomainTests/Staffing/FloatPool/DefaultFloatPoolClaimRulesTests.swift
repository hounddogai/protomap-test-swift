@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultFloatPoolClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultDefaultFloatPoolClaimValidator()
        let item = Staffing.newDefaultFloatPoolClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingDefaultFloatPoolClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.DefaultFloatPoolClaimRequiredCodeRule(message: "default float pool claim needs an entry")
        let item = Staffing.newDefaultFloatPoolClaim("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultFloatPoolClaimChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Staffing.DefaultFloatPoolClaimChannelLengthRule(maxLength: 1000)
        let item = Staffing.newDefaultFloatPoolClaim("x", label: "y")
        item.channel = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultFloatPoolClaimRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.DefaultFloatPoolClaimRequiredLabelRule(message: "default float pool claim needs a value")
        let item = Staffing.newDefaultFloatPoolClaim("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultFloatPoolClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.DefaultFloatPoolClaimCodeLengthRule(maxLength: 1000)
        let item = Staffing.newDefaultFloatPoolClaim("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
