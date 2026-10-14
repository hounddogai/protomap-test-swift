import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped read digest is in its life cycle.
    enum CappedReadDigestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a capped read digest and its current status.
    final class CappedReadDigest {
        var code: String
        var name: String
        var attributes: [String: String]
        var rate: Double
        var bed: String
        var expiresAt: Int
        var status: CappedReadDigestStatus

        init(code: String, name: String, attributes: [String: String], rate: Double, bed: String, expiresAt: Int, status: CappedReadDigestStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.rate = rate
            self.bed = bed
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: CappedReadDigestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
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
                return next == CappedReadDigestStatus.closed
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

        func moveTo(_ next: CappedReadDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped read digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("capped read digest") \(code)"
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

        func adjustedLoad() -> Double {
            return (rate * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> CappedReadDigest {
            return CappedReadDigest(
                code: code,
                name: name,
                attributes: attributes,
                rate: rate,
                bed: bed,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped read digest in status draft.
    static func newCappedReadDigest(_ code: String, name: String) -> CappedReadDigest {
        return CappedReadDigest(
            code: code,
            name: name,
            attributes: [:],
            rate: 0.0,
            bed: "",
            expiresAt: 0,
            status: CappedReadDigestStatus.draft
        )
    }
}
