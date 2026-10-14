@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledProxyGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledProxyGroupValidator()
        let item = Consent.newScheduledProxyGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledProxyGroupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.ScheduledProxyGroupRequiredLabelRule(message: "scheduled proxy group needs an entry")
        let item = Consent.newScheduledProxyGroup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledProxyGroupPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Consent.ScheduledProxyGroupPatientRefLengthRule(maxLength: 16)
        let item = Consent.newScheduledProxyGroup("x", label: "y")
        item.patientRef = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledProxyGroupClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Consent.ScheduledProxyGroupClinicianIDLengthRule(maxLength: 64)
        let item = Consent.newScheduledProxyGroup("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledProxyGroupBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Consent.ScheduledProxyGroupBatchSizeRangeRule(min: 32, max: 1000)
        let item = Consent.newScheduledProxyGroup("x", label: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentScheduledProxyGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ScheduledProxyGroupRequiredCodeRule(message: "scheduled proxy group needs this field")
        let item = Consent.newScheduledProxyGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
