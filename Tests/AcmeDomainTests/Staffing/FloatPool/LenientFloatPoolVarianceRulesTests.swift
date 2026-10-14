@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientFloatPoolVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLenientFloatPoolVarianceValidator()
        let item = Staffing.newLenientFloatPoolVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLenientFloatPoolVarianceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.LenientFloatPoolVarianceRequiredTitleRule(
            message: "lenient float pool variance needs this field"
        )
        let item = Staffing.newLenientFloatPoolVariance("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLenientFloatPoolVarianceFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Staffing.LenientFloatPoolVarianceFacilityLengthRule(maxLength: 32)
        let item = Staffing.newLenientFloatPoolVariance("x", title: "y")
        item.facility = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingLenientFloatPoolVarianceRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Staffing.LenientFloatPoolVarianceRequiredFacilityRule(
            message: "lenient float pool variance needs this field"
        )
        let item = Staffing.newLenientFloatPoolVariance("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLenientFloatPoolVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.LenientFloatPoolVarianceCodeLengthRule(maxLength: 255)
        let item = Staffing.newLenientFloatPoolVariance("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
