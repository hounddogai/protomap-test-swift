import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness audit is in its life cycle.
    enum WitnessAuditStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A witness audit. Its code is unique within a tenant.
    final class WitnessAudit {
        var code: String
        var title: String
        var active: Bool
        var archived: Bool
        var attributes: [String: String]
        var description: String
        var version: Int
        var status: WitnessAuditStatus

        init(code: String, title: String, active: Bool, archived: Bool, attributes: [String: String], description: String, version: Int, status: WitnessAuditStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.archived = archived
            self.attributes = attributes
            self.description = description
            self.version = version
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

        func canMoveTo(_ next: WitnessAuditStatus) -> Bool {
            switch status {
            case .new:
                return next == WitnessAuditStatus.queued || next == WitnessAuditStatus.running
            case .queued:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: WitnessAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("witness audit") \(code)"
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

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> WitnessAudit {
            return WitnessAudit(
                code: code,
                title: title,
                active: active,
                archived: archived,
                attributes: attributes,
                description: description,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a witness audit in status new.
    static func newWitnessAudit(_ code: String, title: String) -> WitnessAudit {
        return WitnessAudit(
            code: code,
            title: title,
            active: false,
            archived: false,
            attributes: [:],
            description: "",
            version: 0,
            status: WitnessAuditStatus.new
        )
    }
}
