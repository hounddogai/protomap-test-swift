import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form exception is in its life cycle.
    enum ConsentFormExceptionStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a consent form exception and its current status.
    final class ConsentFormException {
        var code: String
        var name: String
        var locale: String
        var attributes: [String: String]
        var payer: String
        var createdAt: Int
        var weight: Double
        var rate: Double
        var status: ConsentFormExceptionStatus

        init(code: String, name: String, locale: String, attributes: [String: String], payer: String, createdAt: Int, weight: Double, rate: Double, status: ConsentFormExceptionStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.attributes = attributes
            self.payer = payer
            self.createdAt = createdAt
            self.weight = weight
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ConsentFormExceptionStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ConsentFormExceptionStatus.inProgress || next == ConsentFormExceptionStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ConsentFormExceptionStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func netVolume() -> Double {
            return ((rate - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormException {
            return ConsentFormException(
                code: code,
                name: name,
                locale: locale,
                attributes: attributes,
                payer: payer,
                createdAt: createdAt,
                weight: weight,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a consent form exception in status planned.
    static func newConsentFormException(_ code: String, name: String) -> ConsentFormException {
        return ConsentFormException(
            code: code,
            name: name,
            locale: "",
            attributes: [:],
            payer: "",
            createdAt: 0,
            weight: 0.0,
            rate: 0.0,
            status: ConsentFormExceptionStatus.planned
        )
    }
}
