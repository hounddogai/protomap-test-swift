import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding bundle is in its life cycle.
    enum RoundingBundleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rounding bundle as the rounding team keeps it.
    final class RoundingBundle {
        var code: String
        var name: String
        var visitMinutes: Int
        var expiresAt: Int
        var priority: Int
        var summary: String
        var facility: String
        var status: RoundingBundleStatus

        init(code: String, name: String, visitMinutes: Int, expiresAt: Int, priority: Int, summary: String, facility: String, status: RoundingBundleStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.expiresAt = expiresAt
            self.priority = priority
            self.summary = summary
            self.facility = facility
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

        func canMoveTo(_ next: RoundingBundleStatus) -> Bool {
            switch status {
            case .created:
                return next == RoundingBundleStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RoundingBundleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedExposure() -> Double {
            return (Double(visitMinutes) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> RoundingBundle {
            return RoundingBundle(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                expiresAt: expiresAt,
                priority: priority,
                summary: summary,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a rounding bundle in status created.
    static func newRoundingBundle(_ code: String, name: String) -> RoundingBundle {
        return RoundingBundle(
            code: code,
            name: name,
            visitMinutes: 0,
            expiresAt: 0,
            priority: 0,
            summary: "",
            facility: "",
            status: RoundingBundleStatus.created
        )
    }
}
