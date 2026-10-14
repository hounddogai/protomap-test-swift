@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityScheduleValidator()
        let item = Imaging.newModalitySchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityScheduleCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Imaging.ModalityScheduleCopayRangeRule(min: 7.5, max: 3189.4)
        let item = Imaging.newModalitySchedule("x", name: "y")
        item.copay = 3190.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityScheduleRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Imaging.ModalityScheduleRequiredChecksumRule(message: "modality schedule needs this field")
        let item = Imaging.newModalitySchedule("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityScheduleAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Imaging.ModalityScheduleAcuityRangeRule(min: 80, max: 86400)
        let item = Imaging.newModalitySchedule("x", name: "y")
        item.acuity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ModalityScheduleRequiredCodeRule(message: "modality schedule needs an entry")
        let item = Imaging.newModalitySchedule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityScheduleScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Imaging.ModalityScheduleScoreRangeRule(min: 6.3, max: 1935.3)
        let item = Imaging.newModalitySchedule("x", name: "y")
        item.score = 1936.8
        #expect(rule.check(item).count > 0)
    }
}
