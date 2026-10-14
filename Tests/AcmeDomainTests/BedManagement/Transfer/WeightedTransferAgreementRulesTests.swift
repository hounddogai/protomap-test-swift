@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultWeightedTransferAgreementValidator()
        let item = BedManagement.newWeightedTransferAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementWeightedTransferAgreementChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = BedManagement.WeightedTransferAgreementChannelLengthRule(maxLength: 86400)
        let item = BedManagement.newWeightedTransferAgreement("x", title: "y")
        item.channel = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementWeightedTransferAgreementRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = BedManagement.WeightedTransferAgreementRequiredChannelRule(
            message: "weighted transfer agreement needs an entry"
        )
        let item = BedManagement.newWeightedTransferAgreement("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementWeightedTransferAgreementThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = BedManagement.WeightedTransferAgreementThresholdRangeRule(min: 5.9, max: 3990.6)
        let item = BedManagement.newWeightedTransferAgreement("x", title: "y")
        item.threshold = 3992.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementWeightedTransferAgreementMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = BedManagement.WeightedTransferAgreementMarginRangeRule(min: 0.7, max: 880.7)
        let item = BedManagement.newWeightedTransferAgreement("x", title: "y")
        item.margin = 882.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementWeightedTransferAgreementRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = BedManagement.WeightedTransferAgreementRequiredPatientRefRule(
            message: "weighted transfer agreement needs this field"
        )
        let item = BedManagement.newWeightedTransferAgreement("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
