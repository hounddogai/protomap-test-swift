import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential estimate is in its life cycle.
    enum CredentialEstimateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A credential estimate as the credential team keeps it.
    final class CredentialEstimate {
        var code: String
        var label: String
        var name: String
        var summary: String
        var windowDays: Int
        var limit: Int
        var ratio: Double
        var status: CredentialEstimateStatus

        init(code: String, label: String, name: String, summary: String, windowDays: Int, limit: Int, ratio: Double, status: CredentialEstimateStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.summary = summary
            self.windowDays = windowDays
            self.limit = limit
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CredentialEstimateStatus) -> Bool {
            switch status {
            case .idle:
                return next == CredentialEstimateStatus.ready
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CredentialEstimateStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CredentialEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveTotal() -> Double {
            return ((Double(limit) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> CredentialEstimate {
            return CredentialEstimate(
                code: code,
                label: label,
                name: name,
                summary: summary,
                windowDays: windowDays,
                limit: limit,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a credential estimate in status idle.
    static func newCredentialEstimate(_ code: String, label: String) -> CredentialEstimate {
        return CredentialEstimate(
            code: code,
            label: label,
            name: "",
            summary: "",
            windowDays: 0,
            limit: 0,
            ratio: 0.0,
            status: CredentialEstimateStatus.idle
        )
    }
}
