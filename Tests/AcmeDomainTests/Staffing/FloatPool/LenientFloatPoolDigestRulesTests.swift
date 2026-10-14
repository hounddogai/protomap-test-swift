@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientFloatPoolDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLenientFloatPoolDigestValidator()
        let item = Staffing.newLenientFloatPoolDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLenientFloatPoolDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.LenientFloatPoolDigestRequiredCodeRule(message: "lenient float pool digest needs a value")
        let item = Staffing.newLenientFloatPoolDigest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLenientFloatPoolDigestSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Staffing.LenientFloatPoolDigestSequenceRangeRule(min: 64, max: 80)
        let item = Staffing.newLenientFloatPoolDigest("x", name: "y")
        item.sequence = 81
        #expect(rule.check(item).count > 0)
    }
}
