import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network threshold is in its life cycle.
    enum NetworkThresholdStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a network threshold and its current status.
    final class NetworkThreshold {
        var code: String
        var label: String
        var graceDays: Int
        var pinned: Bool
        var visible: Bool
        var revision: Int
        var discount: Double
        var clinicianID: String
        var facility: String
        var status: NetworkThresholdStatus

        init(code: String, label: String, graceDays: Int, pinned: Bool, visible: Bool, revision: Int, discount: Double, clinicianID: String, facility: String, status: NetworkThresholdStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.pinned = pinned
            self.visible = visible
            self.revision = revision
            self.discount = discount
            self.clinicianID = clinicianID
            self.facility = facility
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

        func canMoveTo(_ next: NetworkThresholdStatus) -> Bool {
            switch status {
            case .new:
                return next == NetworkThresholdStatus.done
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == NetworkThresholdStatus.done || next == NetworkThresholdStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: NetworkThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("network threshold") \(code)"
        }

        func adjustedValue() -> Double {
            return (Double(graceDays) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> NetworkThreshold {
            return NetworkThreshold(
                code: code,
                label: label,
                graceDays: graceDays,
                pinned: pinned,
                visible: visible,
                revision: revision,
                discount: discount,
                clinicianID: clinicianID,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a network threshold in status new.
    static func newNetworkThreshold(_ code: String, label: String) -> NetworkThreshold {
        return NetworkThreshold(
            code: code,
            label: label,
            graceDays: 0,
            pinned: false,
            visible: false,
            revision: 0,
            discount: 0.0,
            clinicianID: "",
            facility: "",
            status: NetworkThresholdStatus.new
        )
    }
}
