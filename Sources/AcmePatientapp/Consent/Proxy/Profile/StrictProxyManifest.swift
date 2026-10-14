import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict proxy manifest is in its life cycle.
    enum StrictProxyManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One strict proxy manifest, with what the planners need to act on it.
    final class StrictProxyManifest {
        var code: String
        var label: String
        var windowDays: Int
        var minimum: Double
        var copay: Double
        var priority: Int
        var contactEmail: String
        var status: StrictProxyManifestStatus

        init(code: String, label: String, windowDays: Int, minimum: Double, copay: Double, priority: Int, contactEmail: String, status: StrictProxyManifestStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.minimum = minimum
            self.copay = copay
            self.priority = priority
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictProxyManifestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == StrictProxyManifestStatus.active
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: StrictProxyManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict proxy manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedValue() -> Double {
            return (Double(windowDays) * minimum * 100).rounded() / 100
        }

        func copyValue() -> StrictProxyManifest {
            return StrictProxyManifest(
                code: code,
                label: label,
                windowDays: windowDays,
                minimum: minimum,
                copay: copay,
                priority: priority,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict proxy manifest in status draft.
    static func newStrictProxyManifest(_ code: String, label: String) -> StrictProxyManifest {
        return StrictProxyManifest(
            code: code,
            label: label,
            windowDays: 0,
            minimum: 0.0,
            copay: 0.0,
            priority: 0,
            contactEmail: "",
            status: StrictProxyManifestStatus.draft
        )
    }
}
