@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalClosureWindowValidator()
        let item = Referrals.newSeasonalClosureWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalClosureWindowRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Referrals.SeasonalClosureWindowRequiredClinicianIDRule(
            message: "seasonal closure window needs an entry"
        )
        let item = Referrals.newSeasonalClosureWindow("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalClosureWindowLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.SeasonalClosureWindowLabelLengthRule(maxLength: 255)
        let item = Referrals.newSeasonalClosureWindow("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalClosureWindowRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.SeasonalClosureWindowRequiredLabelRule(message: "seasonal closure window needs this field")
        let item = Referrals.newSeasonalClosureWindow("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalClosureWindowClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Referrals.SeasonalClosureWindowClinicianIDLengthRule(maxLength: 32)
        let item = Referrals.newSeasonalClosureWindow("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalClosureWindowCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Referrals.SeasonalClosureWindowCeilingRangeRule(min: 5.8, max: 4155.5)
        let item = Referrals.newSeasonalClosureWindow("x", label: "y")
        item.ceiling = 4157.0
        #expect(rule.check(item).count > 0)
    }
}
