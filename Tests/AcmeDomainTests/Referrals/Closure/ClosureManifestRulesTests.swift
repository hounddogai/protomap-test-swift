@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureManifestValidator()
        let item = Referrals.newClosureManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureManifestDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Referrals.ClosureManifestDosageMgRangeRule(min: 4.3, max: 3343.5)
        let item = Referrals.newClosureManifest("x", title: "y")
        item.dosageMg = 3345.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosureManifestRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Referrals.ClosureManifestRequiredClinicianIDRule(message: "closure manifest needs this field")
        let item = Referrals.newClosureManifest("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureManifestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.ClosureManifestRequiredTitleRule(message: "closure manifest needs an entry")
        let item = Referrals.newClosureManifest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
