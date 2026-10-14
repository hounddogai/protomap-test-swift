import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer notice is in its life cycle.
    enum TransferNoticeStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One transfer notice, with what the planners need to act on it.
    final class TransferNotice {
        var code: String
        var label: String
        var floorValue: Double
        var encounterID: String
        var expiresAt: Int
        var pinned: Bool
        var acuity: Int
        var updatedAt: Int
        var margin: Double
        var facility: String
        var source: String
        var status: TransferNoticeStatus

        init(code: String, label: String, floorValue: Double, encounterID: String, expiresAt: Int, pinned: Bool, acuity: Int, updatedAt: Int, margin: Double, facility: String, source: String, status: TransferNoticeStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.encounterID = encounterID
            self.expiresAt = expiresAt
            self.pinned = pinned
            self.acuity = acuity
            self.updatedAt = updatedAt
            self.margin = margin
            self.facility = facility
            self.source = source
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

        func canMoveTo(_ next: TransferNoticeStatus) -> Bool {
            switch status {
            case .new:
                return next == TransferNoticeStatus.failed
            case .queued:
                return next == TransferNoticeStatus.running || next == TransferNoticeStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TransferNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("transfer notice") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(updatedAt) - margin) * 100).rounded() / 100
        }

        func copyValue() -> TransferNotice {
            return TransferNotice(
                code: code,
                label: label,
                floorValue: floorValue,
                encounterID: encounterID,
                expiresAt: expiresAt,
                pinned: pinned,
                acuity: acuity,
                updatedAt: updatedAt,
                margin: margin,
                facility: facility,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a transfer notice in status new.
    static func newTransferNotice(_ code: String, label: String) -> TransferNotice {
        return TransferNotice(
            code: code,
            label: label,
            floorValue: 0.0,
            encounterID: "",
            expiresAt: 0,
            pinned: false,
            acuity: 0,
            updatedAt: 0,
            margin: 0.0,
            facility: "",
            source: "",
            status: TransferNoticeStatus.new
        )
    }
}
