import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending claim estimate is in its life cycle.
    enum PendingClaimEstimateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One pending claim estimate, with what the planners need to act on it.
    final class PendingClaimEstimate {
        var code: String
        var label: String
        var pinned: Bool
        var version: Int
        var ward: String
        var copay: Double
        var ratio: Double
        var retries: Int
        var status: PendingClaimEstimateStatus

        init(code: String, label: String, pinned: Bool, version: Int, ward: String, copay: Double, ratio: Double, retries: Int, status: PendingClaimEstimateStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.version = version
            self.ward = ward
            self.copay = copay
            self.ratio = ratio
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingClaimEstimateStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingClaimEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending claim estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedValue() -> Double {
            return ((ratio + copay) * 100).rounded() / 100
        }

        func copyValue() -> PendingClaimEstimate {
            return PendingClaimEstimate(
                code: code,
                label: label,
                pinned: pinned,
                version: version,
                ward: ward,
                copay: copay,
                ratio: ratio,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a pending claim estimate in status created.
    static func newPendingClaimEstimate(_ code: String, label: String) -> PendingClaimEstimate {
        return PendingClaimEstimate(
            code: code,
            label: label,
            pinned: false,
            version: 0,
            ward: "",
            copay: 0.0,
            ratio: 0.0,
            retries: 0,
            status: PendingClaimEstimateStatus.created
        )
    }
}
