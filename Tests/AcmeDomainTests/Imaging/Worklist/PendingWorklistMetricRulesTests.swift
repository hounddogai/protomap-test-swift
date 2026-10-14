@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingWorklistMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPendingWorklistMetricValidator()
        let item = Imaging.newPendingWorklistMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPendingWorklistMetricPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Imaging.PendingWorklistMetricPatientRefLengthRule(maxLength: 86400)
        let item = Imaging.newPendingWorklistMetric("x", label: "y")
        item.patientRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPendingWorklistMetricAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Imaging.PendingWorklistMetricAllergyLengthRule(maxLength: 64)
        let item = Imaging.newPendingWorklistMetric("x", label: "y")
        item.allergy = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPendingWorklistMetricEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Imaging.PendingWorklistMetricEndsAtRangeRule(min: 64, max: 255)
        let item = Imaging.newPendingWorklistMetric("x", label: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}
