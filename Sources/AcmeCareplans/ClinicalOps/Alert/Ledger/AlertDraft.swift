import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert draft is in its life cycle.
    enum AlertDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A alert draft as the alert team keeps it.
    final class AlertDraft {
        var code: String
        var title: String
        var bed: String
        var procedureCode: String
        var minimum: Double
        var externalRef: String
        var segment: String
        var endsAt: Int
        var attributes: [String: String]
        var attempts: Int
        var weight: Double
        var status: AlertDraftStatus

        init(code: String, title: String, bed: String, procedureCode: String, minimum: Double, externalRef: String, segment: String, endsAt: Int, attributes: [String: String], attempts: Int, weight: Double, status: AlertDraftStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.procedureCode = procedureCode
            self.minimum = minimum
            self.externalRef = externalRef
            self.segment = segment
            self.endsAt = endsAt
            self.attributes = attributes
            self.attempts = attempts
            self.weight = weight
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

        func canMoveTo(_ next: AlertDraftStatus) -> Bool {
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
                return next == AlertDraftStatus.suspended
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

        func moveTo(_ next: AlertDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func netExposure() -> Double {
            return ((Double(attempts) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AlertDraft {
            return AlertDraft(
                code: code,
                title: title,
                bed: bed,
                procedureCode: procedureCode,
                minimum: minimum,
                externalRef: externalRef,
                segment: segment,
                endsAt: endsAt,
                attributes: attributes,
                attempts: attempts,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a alert draft in status draft.
    static func newAlertDraft(_ code: String, title: String) -> AlertDraft {
        return AlertDraft(
            code: code,
            title: title,
            bed: "",
            procedureCode: "",
            minimum: 0.0,
            externalRef: "",
            segment: "",
            endsAt: 0,
            attributes: [:],
            attempts: 0,
            weight: 0.0,
            status: AlertDraftStatus.draft
        )
    }
}
