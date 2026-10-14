import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive census draft is in its life cycle.
    enum AdaptiveCensusDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive census draft. Its code is unique within a tenant.
    final class AdaptiveCensusDraft {
        var code: String
        var label: String
        var diagnosisCode: String
        var checksum: String
        var bed: String
        var acuity: Int
        var allergy: String
        var ratio: Double
        var unit: String
        var cost: Double
        var status: AdaptiveCensusDraftStatus

        init(code: String, label: String, diagnosisCode: String, checksum: String, bed: String, acuity: Int, allergy: String, ratio: Double, unit: String, cost: Double, status: AdaptiveCensusDraftStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.checksum = checksum
            self.bed = bed
            self.acuity = acuity
            self.allergy = allergy
            self.ratio = ratio
            self.unit = unit
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveCensusDraftStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == AdaptiveCensusDraftStatus.expired
            case .revoked:
                return next == AdaptiveCensusDraftStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveCensusDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive census draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netValue() -> Double {
            return ((cost - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCensusDraft {
            return AdaptiveCensusDraft(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                checksum: checksum,
                bed: bed,
                acuity: acuity,
                allergy: allergy,
                ratio: ratio,
                unit: unit,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a adaptive census draft in status requested.
    static func newAdaptiveCensusDraft(_ code: String, label: String) -> AdaptiveCensusDraft {
        return AdaptiveCensusDraft(
            code: code,
            label: label,
            diagnosisCode: "",
            checksum: "",
            bed: "",
            acuity: 0,
            allergy: "",
            ratio: 0.0,
            unit: "",
            cost: 0.0,
            status: AdaptiveCensusDraftStatus.requested
        )
    }
}
