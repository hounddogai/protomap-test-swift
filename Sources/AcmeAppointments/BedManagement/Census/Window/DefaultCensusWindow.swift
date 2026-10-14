import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default census window is in its life cycle.
    enum DefaultCensusWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One default census window, with what the planners need to act on it.
    final class DefaultCensusWindow {
        var code: String
        var label: String
        var source: String
        var attributes: [String: String]
        var refills: Int
        var retries: Int
        var limit: Int
        var status: DefaultCensusWindowStatus

        init(code: String, label: String, source: String, attributes: [String: String], refills: Int, retries: Int, limit: Int, status: DefaultCensusWindowStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.attributes = attributes
            self.refills = refills
            self.retries = retries
            self.limit = limit
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

        func canMoveTo(_ next: DefaultCensusWindowStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: DefaultCensusWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default census window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("default census window") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedVolume() -> Double {
            return (Double(retries) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCensusWindow {
            return DefaultCensusWindow(
                code: code,
                label: label,
                source: source,
                attributes: attributes,
                refills: refills,
                retries: retries,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a default census window in status draft.
    static func newDefaultCensusWindow(_ code: String, label: String) -> DefaultCensusWindow {
        return DefaultCensusWindow(
            code: code,
            label: label,
            source: "",
            attributes: [:],
            refills: 0,
            retries: 0,
            limit: 0,
            status: DefaultCensusWindowStatus.draft
        )
    }
}
