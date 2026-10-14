import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default overtime digest is in its life cycle.
    enum DefaultOvertimeDigestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One default overtime digest, with what the planners need to act on it.
    final class DefaultOvertimeDigest {
        var code: String
        var name: String
        var expiresAt: Int
        var endsAt: Int
        var score: Double
        var attributes: [String: String]
        var checksum: String
        var dosageMg: Double
        var status: DefaultOvertimeDigestStatus

        init(code: String, name: String, expiresAt: Int, endsAt: Int, score: Double, attributes: [String: String], checksum: String, dosageMg: Double, status: DefaultOvertimeDigestStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.endsAt = endsAt
            self.score = score
            self.attributes = attributes
            self.checksum = checksum
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultOvertimeDigestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DefaultOvertimeDigestStatus.inReview
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == DefaultOvertimeDigestStatus.reopened || next == DefaultOvertimeDigestStatus.archived
            case .reopened:
                return next == DefaultOvertimeDigestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultOvertimeDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default overtime digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
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

        func projectedTotal() -> Double {
            return (Double(expiresAt) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> DefaultOvertimeDigest {
            return DefaultOvertimeDigest(
                code: code,
                name: name,
                expiresAt: expiresAt,
                endsAt: endsAt,
                score: score,
                attributes: attributes,
                checksum: checksum,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default overtime digest in status open.
    static func newDefaultOvertimeDigest(_ code: String, name: String) -> DefaultOvertimeDigest {
        return DefaultOvertimeDigest(
            code: code,
            name: name,
            expiresAt: 0,
            endsAt: 0,
            score: 0.0,
            attributes: [:],
            checksum: "",
            dosageMg: 0.0,
            status: DefaultOvertimeDigestStatus.`open`
        )
    }
}
