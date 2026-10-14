import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense audit is in its life cycle.
    enum DispenseAuditStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A dispense audit as the dispense team keeps it.
    final class DispenseAudit {
        var code: String
        var title: String
        var ward: String
        var version: Int
        var createdAt: Int
        var ceiling: Double
        var acuity: Int
        var pinned: Bool
        var retries: Int
        var channel: String
        var attributes: [String: String]
        var status: DispenseAuditStatus

        init(code: String, title: String, ward: String, version: Int, createdAt: Int, ceiling: Double, acuity: Int, pinned: Bool, retries: Int, channel: String, attributes: [String: String], status: DispenseAuditStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.version = version
            self.createdAt = createdAt
            self.ceiling = ceiling
            self.acuity = acuity
            self.pinned = pinned
            self.retries = retries
            self.channel = channel
            self.attributes = attributes
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

        func canMoveTo(_ next: DispenseAuditStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == DispenseAuditStatus.ready || next == DispenseAuditStatus.stopped
            case .ready:
                return next == DispenseAuditStatus.stopped
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

        func moveTo(_ next: DispenseAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("dispense audit") \(code)"
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
            return (Double(acuity) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> DispenseAudit {
            return DispenseAudit(
                code: code,
                title: title,
                ward: ward,
                version: version,
                createdAt: createdAt,
                ceiling: ceiling,
                acuity: acuity,
                pinned: pinned,
                retries: retries,
                channel: channel,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a dispense audit in status idle.
    static func newDispenseAudit(_ code: String, title: String) -> DispenseAudit {
        return DispenseAudit(
            code: code,
            title: title,
            ward: "",
            version: 0,
            createdAt: 0,
            ceiling: 0.0,
            acuity: 0,
            pinned: false,
            retries: 0,
            channel: "",
            attributes: [:],
            status: DispenseAuditStatus.idle
        )
    }
}
