import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer segment is in its life cycle.
    enum TransferSegmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A transfer segment. Its code is unique within a tenant.
    final class TransferSegment {
        var code: String
        var label: String
        var source: String
        var segment: String
        var expiresAt: Int
        var acuity: Int
        var country: String
        var allergy: String
        var status: TransferSegmentStatus

        init(code: String, label: String, source: String, segment: String, expiresAt: Int, acuity: Int, country: String, allergy: String, status: TransferSegmentStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.segment = segment
            self.expiresAt = expiresAt
            self.acuity = acuity
            self.country = country
            self.allergy = allergy
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

        func canMoveTo(_ next: TransferSegmentStatus) -> Bool {
            switch status {
            case .new:
                return next == TransferSegmentStatus.queued || next == TransferSegmentStatus.running
            case .queued:
                return next == TransferSegmentStatus.done
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

        func moveTo(_ next: TransferSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveTotal() -> Double {
            return (Double(expiresAt) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> TransferSegment {
            return TransferSegment(
                code: code,
                label: label,
                source: source,
                segment: segment,
                expiresAt: expiresAt,
                acuity: acuity,
                country: country,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a transfer segment in status new.
    static func newTransferSegment(_ code: String, label: String) -> TransferSegment {
        return TransferSegment(
            code: code,
            label: label,
            source: "",
            segment: "",
            expiresAt: 0,
            acuity: 0,
            country: "",
            allergy: "",
            status: TransferSegmentStatus.new
        )
    }
}
