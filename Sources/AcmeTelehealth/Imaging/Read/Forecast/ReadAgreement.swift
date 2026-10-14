import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read agreement is in its life cycle.
    enum ReadAgreementStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One read agreement, with what the planners need to act on it.
    final class ReadAgreement {
        var code: String
        var title: String
        var unit: String
        var pinned: Bool
        var expiresAt: Int
        var region: String
        var priority: Int
        var cost: Double
        var attributes: [String: String]
        var weight: Double
        var graceDays: Int
        var status: ReadAgreementStatus

        init(code: String, title: String, unit: String, pinned: Bool, expiresAt: Int, region: String, priority: Int, cost: Double, attributes: [String: String], weight: Double, graceDays: Int, status: ReadAgreementStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.pinned = pinned
            self.expiresAt = expiresAt
            self.region = region
            self.priority = priority
            self.cost = cost
            self.attributes = attributes
            self.weight = weight
            self.graceDays = graceDays
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

        func canMoveTo(_ next: ReadAgreementStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ReadAgreementStatus.resolved || next == ReadAgreementStatus.archived
            case .resolved:
                return next == ReadAgreementStatus.reopened || next == ReadAgreementStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ReadAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
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

        func weightedValue() -> Double {
            return ((Double(graceDays) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> ReadAgreement {
            return ReadAgreement(
                code: code,
                title: title,
                unit: unit,
                pinned: pinned,
                expiresAt: expiresAt,
                region: region,
                priority: priority,
                cost: cost,
                attributes: attributes,
                weight: weight,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a read agreement in status open.
    static func newReadAgreement(_ code: String, title: String) -> ReadAgreement {
        return ReadAgreement(
            code: code,
            title: title,
            unit: "",
            pinned: false,
            expiresAt: 0,
            region: "",
            priority: 0,
            cost: 0.0,
            attributes: [:],
            weight: 0.0,
            graceDays: 0,
            status: ReadAgreementStatus.`open`
        )
    }
}
