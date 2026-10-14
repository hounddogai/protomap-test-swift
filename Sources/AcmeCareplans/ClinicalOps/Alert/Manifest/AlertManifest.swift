import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert manifest is in its life cycle.
    enum AlertManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a alert manifest and its current status.
    final class AlertManifest {
        var code: String
        var name: String
        var acuity: Int
        var visitMinutes: Int
        var pinned: Bool
        var attributes: [String: String]
        var maximum: Double
        var status: AlertManifestStatus

        init(code: String, name: String, acuity: Int, visitMinutes: Int, pinned: Bool, attributes: [String: String], maximum: Double, status: AlertManifestStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.visitMinutes = visitMinutes
            self.pinned = pinned
            self.attributes = attributes
            self.maximum = maximum
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

        func canMoveTo(_ next: AlertManifestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
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

        func moveTo(_ next: AlertManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("alert manifest") \(code)"
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

        func effectiveValue() -> Double {
            return ((Double(acuity) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> AlertManifest {
            return AlertManifest(
                code: code,
                name: name,
                acuity: acuity,
                visitMinutes: visitMinutes,
                pinned: pinned,
                attributes: attributes,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a alert manifest in status created.
    static func newAlertManifest(_ code: String, name: String) -> AlertManifest {
        return AlertManifest(
            code: code,
            name: name,
            acuity: 0,
            visitMinutes: 0,
            pinned: false,
            attributes: [:],
            maximum: 0.0,
            status: AlertManifestStatus.created
        )
    }
}
