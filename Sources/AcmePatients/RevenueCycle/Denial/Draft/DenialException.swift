import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial exception is in its life cycle.
    enum DenialExceptionStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a denial exception and its current status.
    final class DenialException {
        var code: String
        var title: String
        var expiresAt: Int
        var updatedAt: Int
        var attributes: [String: String]
        var description: String
        var windowDays: Int
        var segment: String
        var unit: String
        var active: Bool
        var status: DenialExceptionStatus

        init(code: String, title: String, expiresAt: Int, updatedAt: Int, attributes: [String: String], description: String, windowDays: Int, segment: String, unit: String, active: Bool, status: DenialExceptionStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.updatedAt = updatedAt
            self.attributes = attributes
            self.description = description
            self.windowDays = windowDays
            self.segment = segment
            self.unit = unit
            self.active = active
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

        func canMoveTo(_ next: DenialExceptionStatus) -> Bool {
            switch status {
            case .created:
                return next == DenialExceptionStatus.published || next == DenialExceptionStatus.retired
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

        func moveTo(_ next: DenialExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("denial exception") \(code)"
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

        func weightedLoad() -> Double {
            return ((Double(updatedAt) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> DenialException {
            return DenialException(
                code: code,
                title: title,
                expiresAt: expiresAt,
                updatedAt: updatedAt,
                attributes: attributes,
                description: description,
                windowDays: windowDays,
                segment: segment,
                unit: unit,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a denial exception in status created.
    static func newDenialException(_ code: String, title: String) -> DenialException {
        return DenialException(
            code: code,
            title: title,
            expiresAt: 0,
            updatedAt: 0,
            attributes: [:],
            description: "",
            windowDays: 0,
            segment: "",
            unit: "",
            active: false,
            status: DenialExceptionStatus.created
        )
    }
}
