import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped eligibility mapping is in its life cycle.
    enum CappedEligibilityMappingStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One capped eligibility mapping, with what the planners need to act on it.
    final class CappedEligibilityMapping {
        var code: String
        var title: String
        var ward: String
        var unit: String
        var ratio: Double
        var clinicianID: String
        var sequence: Int
        var status: CappedEligibilityMappingStatus

        init(code: String, title: String, ward: String, unit: String, ratio: Double, clinicianID: String, sequence: Int, status: CappedEligibilityMappingStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.unit = unit
            self.ratio = ratio
            self.clinicianID = clinicianID
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedEligibilityMappingStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CappedEligibilityMappingStatus.running
            case .running:
                return next == CappedEligibilityMappingStatus.done || next == CappedEligibilityMappingStatus.failed
            case .done:
                return next == CappedEligibilityMappingStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedEligibilityMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped eligibility mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedVolume() -> Double {
            return ((ratio - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> CappedEligibilityMapping {
            return CappedEligibilityMapping(
                code: code,
                title: title,
                ward: ward,
                unit: unit,
                ratio: ratio,
                clinicianID: clinicianID,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a capped eligibility mapping in status new.
    static func newCappedEligibilityMapping(_ code: String, title: String) -> CappedEligibilityMapping {
        return CappedEligibilityMapping(
            code: code,
            title: title,
            ward: "",
            unit: "",
            ratio: 0.0,
            clinicianID: "",
            sequence: 0,
            status: CappedEligibilityMappingStatus.new
        )
    }
}
