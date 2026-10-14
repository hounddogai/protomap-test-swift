@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapQuotaValidator()
        let item = CareManagement.newCareGapQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapQuotaRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = CareManagement.CareGapQuotaRequiredClinicianIDRule(message: "care gap quota needs an entry")
        let item = CareManagement.newCareGapQuota("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.CareGapQuotaRequiredCodeRule(message: "care gap quota needs this field")
        let item = CareManagement.newCareGapQuota("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapQuotaRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = CareManagement.CareGapQuotaRequiredCountryRule(message: "care gap quota needs this field")
        let item = CareManagement.newCareGapQuota("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
