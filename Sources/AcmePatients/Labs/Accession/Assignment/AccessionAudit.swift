import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession audit is in its life cycle.
    enum AccessionAuditStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A accession audit as the accession team keeps it.
    final class AccessionAudit {
        var code: String
        var label: String
        var ward: String
        var maximum: Double
        var minimum: Double
        var durationMinutes: Int
        var status: AccessionAuditStatus

        init(code: String, label: String, ward: String, maximum: Double, minimum: Double, durationMinutes: Int, status: AccessionAuditStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.maximum = maximum
            self.minimum = minimum
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: AccessionAuditStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == AccessionAuditStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netLoad() -> Double {
            return ((maximum + minimum) * 100).rounded() / 100
        }

        func copyValue() -> AccessionAudit {
            return AccessionAudit(
                code: code,
                label: label,
                ward: ward,
                maximum: maximum,
                minimum: minimum,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a accession audit in status new.
    static func newAccessionAudit(_ code: String, label: String) -> AccessionAudit {
        return AccessionAudit(
            code: code,
            label: label,
            ward: "",
            maximum: 0.0,
            minimum: 0.0,
            durationMinutes: 0,
            status: AccessionAuditStatus.new
        )
    }
}
